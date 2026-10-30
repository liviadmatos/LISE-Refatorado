import uuid
from datetime import datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

import pytest
from sqlalchemy import select
from sqlalchemy.orm import Session

from app import create_app
from backend.demo import ALUNO_ID, seed
from backend.models import (Avaliacao, AvaliacaoQuestao, Base, GameSession, Partida,
                            Progresso, Turma, TurmaTrilha, Usuario)


@pytest.fixture
def app():
    app = create_app({
        'TESTING': True,
        'DEMO_MODE': True,
        'DATABASE_URL': 'sqlite:///:memory:',
        'SECRET_KEY': 'test-secret-with-more-than-thirty-two-characters',
        'FRONTEND_ORIGINS': 'https://lise.example',
        'FRONTEND_URL': 'https://lise.example',
    })
    Base.metadata.create_all(app.extensions['engine'])
    with Session(app.extensions['engine']) as db:
        seed(db)
        db.commit()
    return app


def login(client, email='aluno@lise.demo'):
    response = client.post('/api/v1/auth/login', json={'email': email, 'password': 'LiseDemo123!'})
    assert response.status_code == 200, response.json
    return {'Authorization': f"Bearer {response.json['access_token']}"}


def test_auth_cors_private_terms_and_no_isolated_term_practice(app):
    client = app.test_client()
    assert client.get('/api/v1/classes').status_code == 401
    headers = login(client)
    response = client.get('/api/v1/explore?kind=both', headers={**headers, 'Origin': 'https://lise.example'})
    assert response.status_code == 200
    assert response.headers['Access-Control-Allow-Origin'] == 'https://lise.example'
    assert len(response.json['terms']) == 7
    created = client.post('/api/v1/me/terms', headers=headers, json={
        'name': 'Palavra pessoal', 'definition': 'Termo criado pela aluna.'})
    assert created.status_code == 201
    term_id = created.json['term']['id']
    assert created.json['term']['radical_list'] == []
    assert created.json['term']['private'] is True
    collection = client.post('/api/v1/collections', headers=headers,
                             json={'name': 'Minha coleção', 'term_ids': [term_id, 1]})
    assert collection.status_code == 201
    created_term = next(item for item in collection.json['collection']['terms'] if item['id'] == term_id)
    assert created_term['created_by_me'] is True
    bioquiz = client.post('/api/v1/games/sessions', headers=headers, json={
        'game': 'bioquiz', 'source_type': 'collection', 'source_id': collection.json['collection']['id'],
        'mode': 'definicao_termo', 'question_count': 2})
    assert bioquiz.status_code == 201, bioquiz.json
    assert len(bioquiz.json['questions']) == 2
    isolated = client.post('/api/v1/games/sessions', headers=headers, json={
        'game': 'decifrador', 'source_type': 'term', 'source_id': term_id})
    assert isolated.status_code == 400
    with Session(app.extensions['engine']) as db:
        other_id = str(uuid.uuid4())
        db.add(Usuario(id_usuario=other_id, nome='Outra aluna', email='outra@lise.demo', perfil='Aluno'))
        db.commit()
    other = app.test_client()
    other_headers = login(other, 'outra@lise.demo')
    terms = other.get('/api/v1/catalog/terms', headers=other_headers).json['terms']
    assert term_id not in [item['id'] for item in terms]


def test_bioquiz_is_active_and_removed_games_are_rejected(app):
    student = app.test_client()
    headers = login(student)
    for removed_game in ('montagem', 'flashcard'):
        response = student.post('/api/v1/games/sessions', headers=headers, json={
            'game': removed_game, 'source_type': 'area', 'area': 'Biologia Geral'})
        assert response.status_code == 400
    quiz = student.post('/api/v1/games/sessions', headers=headers, json={
        'game': 'bioquiz', 'source_type': 'area', 'area': 'Biologia Geral',
        'mode': 'termo_definicao', 'question_count': 5})
    assert quiz.status_code == 201, quiz.json
    assert len(quiz.json['questions']) == 5
    assert all(question['options'] and question['prompt'] for question in quiz.json['questions'])
    started = student.post('/api/v1/games/sessions', headers=headers, json={
        'game': 'memoria', 'source_type': 'area', 'area': 'Biologia Geral',
        'mode': 'termo_definicao', 'question_count': 6})
    assert started.status_code == 201, started.json
    question = started.json['questions'][0]
    assert len(question['cards']) >= 4 and len(question['cards']) % 2 == 0
    assert '_coverage_map' not in question


def test_teacher_custom_term_uses_only_name_and_definition(app):
    teacher = app.test_client()
    headers = login(teacher, 'professor@lise.demo')
    response = teacher.post('/api/v1/terms', headers=headers, json={
        'name': 'Termo da professora',
        'definition': 'Definição informada pela professora.',
        'class_ids': [1],
    })
    assert response.status_code == 201, response.json
    assert response.json['term']['radical_list'] == []
    assert response.json['term']['private'] is False
    student = app.test_client()
    student_headers = login(student)
    visible = student.get('/api/v1/catalog/terms', headers=student_headers).json['terms']
    found = next(term for term in visible if term['name'] == 'Termo da professora')
    assert found['radical_list'] == []


def test_family_options_are_validated_and_memory_requires_server_recorded_matches(app):
    student = app.test_client()
    headers = login(student)
    family = student.post('/api/v1/games/sessions', headers=headers, json={
        'game': 'familia_palavras', 'source_type': 'area', 'area': 'Biologia Geral'})
    assert family.status_code == 201, family.json
    family_question = family.json['questions'][0]
    invalid = student.post(f"/api/v1/games/sessions/{family.json['session_id']}/answer",
                           headers=headers,
                           json={'question_id': family_question['id'], 'answer': [999999]})
    assert invalid.status_code == 400

    memory = student.post('/api/v1/games/sessions', headers=headers, json={
        'game': 'memoria', 'source_type': 'area', 'area': 'Biologia Geral',
        'mode': 'termo_definicao', 'question_count': 6})
    assert memory.status_code == 201, memory.json
    memory_question = memory.json['questions'][0]
    with Session(app.extensions['engine']) as db:
        expected = db.get(Partida, memory_question['id']).resposta_esperada
    forged = student.post(f"/api/v1/games/sessions/{memory.json['session_id']}/answer",
                          headers=headers,
                          json={'question_id': memory_question['id'], 'answer': expected})
    assert forged.status_code == 409

    for pair in expected:
        matched = student.post(f"/api/v1/games/sessions/{memory.json['session_id']}/match",
                               headers=headers,
                               json={'question_id': memory_question['id'], 'pair': pair})
        assert matched.status_code == 200 and matched.json['match'] is True
        duplicate = student.post(f"/api/v1/games/sessions/{memory.json['session_id']}/match",
                                 headers=headers,
                                 json={'question_id': memory_question['id'], 'pair': pair})
        assert duplicate.status_code == 200 and duplicate.json['duplicate'] is True
        assert duplicate.json['attempts'] == matched.json['attempts']
    submitted = student.post(f"/api/v1/games/sessions/{memory.json['session_id']}/answer",
                             headers=headers,
                             json={'question_id': memory_question['id'], 'answer': []})
    assert submitted.status_code == 200 and submitted.json['correct'] is True


def test_trail_requires_practice_of_every_term_then_teacher_assessment(app):
    teacher = app.test_client()
    teacher_headers = login(teacher, 'professor@lise.demo')
    trail = teacher.post('/api/v1/trails', headers=teacher_headers, json={
        'name': 'Trilha de teste', 'term_ids': [1, 2, 3], 'class_ids': [1],
        'due_date': (datetime.now(timezone.utc) + timedelta(days=7)).date().isoformat()})
    assert trail.status_code == 201, trail.json
    trail_id = trail.json['trail']['id']
    with Session(app.extensions['engine']) as db:
        assignment_id = db.scalar(select(TurmaTrilha.id).where(TurmaTrilha.fk_trilha == trail_id))
    now = datetime.now(timezone.utc)
    config = teacher.post(f'/api/v1/classes/1/trails/{assignment_id}/assessment', headers=teacher_headers, json={
        'title': 'BioQuiz de etimologia', 'question_count': 6, 'content': 'ambos',
        'mode': 'misto', 'pass_score': 70, 'opens_at': (now - timedelta(minutes=1)).isoformat(),
        'closes_at': (now + timedelta(hours=1)).isoformat()})
    assert config.status_code == 200, config.json
    assert config.json['assessment']['opens_at']
    assert config.json['assessment']['closes_at']

    student = app.test_client()
    student_headers = login(student)
    blocked = student.post(f'/api/v1/classes/1/trails/{assignment_id}/assessment/sessions',
                           headers=student_headers, json={})
    assert blocked.status_code == 409

    practice = student.post('/api/v1/games/sessions', headers=student_headers, json={
        'game': 'decifrador', 'source_type': 'trail', 'source_id': assignment_id, 'question_count': 3})
    assert practice.status_code == 201, practice.json
    for question in practice.json['questions']:
        response = student.post(f"/api/v1/games/sessions/{practice.json['session_id']}/answer",
                                headers=student_headers,
                                json={'question_id': question['id'], 'answer': 'resposta errada'})
        assert response.status_code == 200 and response.json['correct'] is False
    student.post(f"/api/v1/games/sessions/{practice.json['session_id']}/finish",
                 headers=student_headers, json={})
    class_detail = student.get('/api/v1/classes/1', headers=student_headers).json
    trail_view = next(item for item in class_detail['trails'] if item['assignment_id'] == assignment_id)
    assert trail_view['played'] == 3
    assert trail_view['progress'] == 100
    assert trail_view['assessment']['can_start'] is True

    assessment = student.post(f'/api/v1/classes/1/trails/{assignment_id}/assessment/sessions',
                              headers=student_headers, json={})
    assert assessment.status_code == 201, assessment.json
    for question in assessment.json['questions']:
        with Session(app.extensions['engine']) as db:
            expected = db.get(AvaliacaoQuestao, question['id']).resposta_esperada
        answer = student.post(f"/api/v1/assessment/sessions/{assessment.json['session_id']}/answer",
                              headers=student_headers,
                              json={'question_id': question['id'], 'answer': expected})
        assert answer.status_code == 200 and answer.json['correct'] is True
    finished = student.post(f"/api/v1/assessment/sessions/{assessment.json['session_id']}/finish",
                            headers=student_headers, json={})
    assert finished.status_code == 200 and finished.json['passed'] is True
    assert finished.json['score'] == 100

    report = teacher.get('/api/v1/classes/1', headers=teacher_headers)
    assert report.status_code == 200
    assert any(item['score'] == 100 for item in report.json['assessment_results'])
    assert report.json['students'][0]['last_access'] is not None
    details = teacher.get(f'/api/v1/classes/1/students/{ALUNO_ID}', headers=teacher_headers)
    assert details.status_code == 200
    own_assignment = next(item for item in details.json['trails'] if item['assignment_id'] == assignment_id)
    assert own_assignment['completed'] is True
    assert own_assignment['attempts'][0]['score'] == 100


def test_assessment_window_controls_start_answers_and_trail_deadline(app):
    teacher = app.test_client()
    teacher_headers = login(teacher, 'professor@lise.demo')
    trail = teacher.post('/api/v1/trails', headers=teacher_headers, json={
        'name': 'BioQuiz agendado', 'term_ids': [1, 2, 3], 'class_ids': [1],
        'due_date': (datetime.now(timezone.utc) + timedelta(days=7)).date().isoformat()})
    assert trail.status_code == 201, trail.json
    with Session(app.extensions['engine']) as db:
        assignment_id = db.scalar(select(TurmaTrilha.id).where(
            TurmaTrilha.fk_trilha == trail.json['trail']['id']))

    now = datetime.now(timezone.utc)
    closes_at = now + timedelta(hours=2)
    config = teacher.post(f'/api/v1/classes/1/trails/{assignment_id}/assessment',
                          headers=teacher_headers, json={
                              'title': 'BioQuiz agendado', 'question_count': 3,
                              'content': 'termos', 'mode': 'misto', 'pass_score': 70,
                              'opens_at': (now + timedelta(hours=1)).isoformat(),
                              'closes_at': closes_at.isoformat()})
    assert config.status_code == 200, config.json

    student = app.test_client()
    student_headers = login(student)
    practice = student.post('/api/v1/games/sessions', headers=student_headers, json={
        'game': 'decifrador', 'source_type': 'trail', 'source_id': assignment_id,
        'question_count': 3})
    assert practice.status_code == 201, practice.json
    for question in practice.json['questions']:
        answer = student.post(f"/api/v1/games/sessions/{practice.json['session_id']}/answer",
                              headers=student_headers,
                              json={'question_id': question['id'], 'answer': 'resposta errada'})
        assert answer.status_code == 200
    student.post(f"/api/v1/games/sessions/{practice.json['session_id']}/finish",
                 headers=student_headers, json={})

    class_detail = student.get('/api/v1/classes/1', headers=student_headers)
    trail_view = next(item for item in class_detail.json['trails']
                      if item['assignment_id'] == assignment_id)
    assert trail_view['assessment']['window_state'] == 'agendado'
    assert trail_view['assessment']['can_start'] is False
    assert trail_view['due_date'] == config.json['assessment']['closes_at']
    too_early = student.post(
        f'/api/v1/classes/1/trails/{assignment_id}/assessment/sessions',
        headers=student_headers, json={})
    assert too_early.status_code == 409

    with Session(app.extensions['engine']) as db:
        assessment = db.scalar(select(Avaliacao).where(
            Avaliacao.fk_turma_trilha == assignment_id))
        assessment.abre_em = datetime.now(timezone.utc) - timedelta(minutes=1)
        assessment.encerra_em = datetime.now(timezone.utc) + timedelta(hours=1)
        db.commit()
    started = student.post(
        f'/api/v1/classes/1/trails/{assignment_id}/assessment/sessions',
        headers=student_headers, json={})
    assert started.status_code == 201, started.json

    with Session(app.extensions['engine']) as db:
        assessment = db.scalar(select(Avaliacao).where(
            Avaliacao.fk_turma_trilha == assignment_id))
        assessment.encerra_em = datetime.now(timezone.utc) - timedelta(seconds=1)
        db.commit()
    question = started.json['questions'][0]
    after_close = student.post(
        f"/api/v1/assessment/sessions/{started.json['session_id']}/answer",
        headers=student_headers, json={'question_id': question['id'],
                                       'answer': question['options'][0]['id']})
    assert after_close.status_code == 409
    expired_detail = student.get('/api/v1/classes/1', headers=student_headers)
    expired_trail = next(item for item in expired_detail.json['trails']
                         if item['assignment_id'] == assignment_id)
    assert expired_trail['assessment']['window_state'] == 'encerrado'
    assert expired_trail['status'] == 'atrasado'


def test_student_trail_details_are_scoped_and_class_feed_is_removed(app):
    teacher = app.test_client()
    teacher_headers = login(teacher, 'professor@lise.demo')
    second_class = teacher.post('/api/v1/classes', headers=teacher_headers, json={'name': 'Outra turma'})
    assert second_class.status_code == 201
    class_id = second_class.json['id']
    student = app.test_client()
    student_headers = login(student)
    joined = student.post('/api/v1/classes/join', headers=student_headers,
                          json={'code': second_class.json['code']})
    assert joined.status_code == 200
    second_trail = teacher.post('/api/v1/trails', headers=teacher_headers, json={
        'name': 'Trilha da segunda turma', 'term_ids': [4, 5], 'class_ids': [class_id]})
    assert second_trail.status_code == 201
    first_detail = teacher.get(f'/api/v1/classes/1/students/{ALUNO_ID}', headers=teacher_headers).json
    assert all(item['name'] != 'Trilha da segunda turma' for item in first_detail['trails'])
    second_detail = teacher.get(f'/api/v1/classes/{class_id}/students/{ALUNO_ID}', headers=teacher_headers).json
    assert [item['name'] for item in second_detail['trails']] == ['Trilha da segunda turma']

    opened_class = student.get('/api/v1/classes/1', headers=student_headers)
    assert opened_class.status_code == 200
    assert 'feed' not in opened_class.json
    assert 'leaderboard' in opened_class.json


def test_teacher_registration_does_not_need_invite_code():
    class AuthStub:
        def __init__(self):
            self.auth = self

        def sign_up(self, _payload):
            return None

    auth = AuthStub()
    app = create_app({
        'TESTING': True,
        'DEMO_MODE': False,
        'DATABASE_URL': 'sqlite:///:memory:',
        'SECRET_KEY': 'test-secret-with-more-than-thirty-two-characters',
        'AUTH_FACTORY': lambda: auth,
    })
    Base.metadata.create_all(app.extensions['engine'])
    client = app.test_client()
    payload = {'name': 'Professora', 'email': 'prof@lise.test', 'password': 'SenhaForte123', 'role': 'PROFESSOR'}
    response = client.post('/api/v1/auth/register', json=payload)
    assert response.status_code == 201


def test_profile_avatar_and_demo_password_are_editable(app):
    client = app.test_client()
    headers = login(client)
    profile = client.get('/api/v1/auth/me', headers=headers)
    assert profile.json['user']['avatar'] == 'leaf'

    invalid_avatar = client.patch('/api/v1/auth/profile', headers=headers, json={'avatar': 'upload'})
    assert invalid_avatar.status_code == 400
    changed_avatar = client.patch('/api/v1/auth/profile', headers=headers, json={'avatar': 'cell'})
    assert changed_avatar.status_code == 200
    assert changed_avatar.json['user']['avatar'] == 'cell'

    wrong_password = client.post('/api/v1/auth/change-password', headers=headers,
                                json={'current_password': 'wrong', 'password': 'SenhaNova123'})
    assert wrong_password.status_code == 401
    changed_password = client.post('/api/v1/auth/change-password', headers=headers,
                                   json={'current_password': 'LiseDemo123!', 'password': 'SenhaNova123'})
    assert changed_password.status_code == 200
    assert client.post('/api/v1/auth/login', json={
        'email': 'aluno@lise.demo', 'password': 'SenhaNova123'}).status_code == 200
    assert client.post('/api/v1/auth/login', json={
        'email': 'aluno@lise.demo', 'password': 'LiseDemo123!'}).status_code == 401


def test_weekly_class_ranking_only_counts_current_week_activities(app):
    teacher = app.test_client()
    teacher_headers = login(teacher, 'professor@lise.demo')
    trail = teacher.post('/api/v1/trails', headers=teacher_headers, json={
        'name': 'Atividades semanais', 'term_ids': [1], 'class_ids': [1]})
    assert trail.status_code == 201
    with Session(app.extensions['engine']) as db:
        assignment_id = db.scalar(select(TurmaTrilha.id).where(
            TurmaTrilha.fk_trilha == trail.json['trail']['id']))
        today = datetime.now(ZoneInfo('America/Sao_Paulo')).date()
        monday = today - timedelta(days=today.weekday())
        week_start = datetime.combine(monday, time.min, tzinfo=ZoneInfo('America/Sao_Paulo'))
        timestamps = [
            (week_start + timedelta(minutes=1), 10),
            (week_start + timedelta(days=6, hours=23, minutes=59), 5),
            (week_start + timedelta(days=7), 50),
            (week_start - timedelta(seconds=1), 25),
        ]
        db.add_all([
            Partida(id=str(uuid.uuid4()), fk_usuario=ALUNO_ID, fk_termo=1,
                    fk_turma_trilha=assignment_id, jogo='decifrador',
                    resposta_esperada='x', respondida=True, xp=xp,
                    respondida_em=played_at.astimezone(timezone.utc))
            for played_at, xp in timestamps
        ])
        db.commit()

    student = app.test_client()
    student_headers = login(student)
    response = student.get('/api/v1/classes/1', headers=student_headers)
    assert response.status_code == 200
    assert response.json['week_start'] == monday.isoformat()
    row = next(item for item in response.json['weekly_leaderboard'] if item['user_id'] == ALUNO_ID)
    assert row['xp'] == 15


def test_trail_games_prioritize_terms_not_played_yet(app):
    teacher = app.test_client()
    teacher_headers = login(teacher, 'professor@lise.demo')
    trail = teacher.post('/api/v1/trails', headers=teacher_headers, json={
        'name': 'Prioridade de termos', 'term_ids': [1, 2, 3], 'class_ids': [1]})
    assert trail.status_code == 201
    with Session(app.extensions['engine']) as db:
        assignment_id = db.scalar(select(TurmaTrilha.id).where(
            TurmaTrilha.fk_trilha == trail.json['trail']['id']))
        db.add(Progresso(fk_usuario=ALUNO_ID, fk_turma_trilha=assignment_id,
                         fk_termo=1, jogado=True, acertou=False))
        db.commit()

    student = app.test_client()
    headers = login(student)
    started = student.post('/api/v1/games/sessions', headers=headers, json={
        'game': 'decifrador', 'source_type': 'trail', 'source_id': assignment_id,
        'question_count': 2})
    assert started.status_code == 201, started.json
    question_ids = [question['id'] for question in started.json['questions']]
    with Session(app.extensions['engine']) as db:
        term_ids = set(db.scalars(select(Partida.fk_termo).where(Partida.id.in_(question_ids))))
    assert term_ids == {2, 3}


def test_term_catalog_search_matches_definitions_and_collection_can_add_terms(app):
    student = app.test_client()
    headers = login(student)
    found = student.get('/api/v1/catalog/terms?search=ecossistemas', headers=headers)
    assert found.status_code == 200
    assert any(term['id'] == 2 for term in found.json['terms'])
    collection = student.post('/api/v1/collections', headers=headers,
                              json={'name': 'Busca ativa', 'term_ids': [1]})
    assert collection.status_code == 201
    added = student.post(f"/api/v1/collections/{collection.json['collection']['id']}/terms",
                         headers=headers, json={'term_ids': [2]})
    assert added.status_code == 200
    assert {term['id'] for term in added.json['collection']['terms']} == {1, 2}


def test_teacher_can_add_terms_to_an_existing_trail(app):
    teacher = app.test_client()
    teacher_headers = login(teacher, 'professor@lise.demo')
    trail = teacher.post('/api/v1/trails', headers=teacher_headers, json={
        'name': 'Trilha editável', 'term_ids': [1]})
    assert trail.status_code == 201
    trail_id = trail.json['trail']['id']
    added = teacher.post(f'/api/v1/trails/{trail_id}/terms', headers=teacher_headers,
                         json={'term_ids': [2, 3]})
    assert added.status_code == 200
    assert set(added.json['trail']['terms']) == {1, 2, 3}

    student = app.test_client()
    student_headers = login(student)
    forbidden = student.post(f'/api/v1/trails/{trail_id}/terms', headers=student_headers,
                             json={'term_ids': [4]})
    assert forbidden.status_code == 403
