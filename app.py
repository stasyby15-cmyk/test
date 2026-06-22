import streamlit as st
import json
import random

# -------------------- Загрузка данных --------------------
@st.cache_data
def load_questions(filename="questions.json"):
    """Загружает список вопросов из JSON."""
    with open(filename, "r", encoding="utf-8") as f:
        return json.load(f)

@st.cache_data
def load_dates(filename="dates.json"):
    """Загружает пары дата-событие из JSON."""
    with open(filename, "r", encoding="utf-8") as f:
        return json.load(f)

# -------------------- Инициализация сессии --------------------
if "page" not in st.session_state:
    st.session_state.page = "menu"

# -------------------- Основное меню --------------------
def show_menu():
    st.title("Выберите режим обучения")
    col1, col2, _ = st.columns([1, 1, 2])
    with col1:
        if st.button("📝 Тесты", use_container_width=True):
            st.session_state.page = "quiz"
            # Инициализация состояния для тестов
            st.session_state.quiz = {
                "questions": load_questions(),
                "current": 0,
                "score": 0,
                "answered": False,       # Был ли дан ответ на текущий вопрос
                "selected": None,        # Индекс выбранного ответа
                "feedback": None         # "correct" / "wrong"
            }
            st.rerun()
    with col2:
        if st.button("📅 Даты и события", use_container_width=True):
            st.session_state.page = "match"
            # Инициализация состояния для игры в даты
            pairs = load_dates()
            st.session_state.match = {
                "pairs": pairs,
                "offset": 0,
                "batch_size": 10,
                "selected_date": None,
                "selected_event": None,
                "matched": {},           # ключ: дата, значение: событие (только правильные)
                "wrong_pair": None       # временная подсветка ошибки
            }
            st.rerun()

# -------------------- Режим тестов --------------------
def show_quiz():
    quiz = st.session_state.quiz
    questions = quiz["questions"]
    total = len(questions)

    # Если все вопросы пройдены — показать результат
    if quiz["current"] >= total:
        st.success(f"🎉 Тест завершён! Ваш результат: {quiz['score']}/{total}")
        if st.button("← Вернуться в меню"):
            st.session_state.page = "menu"
            st.rerun()
        return

    # Текущий вопрос
    q = questions[quiz["current"]]
    progress = quiz["current"]
    st.progress(progress / total, text=f"Вопрос {progress+1} из {total}")

    st.subheader(q["question"])

    answers = q["answers"]
    correct_idx = q["correct"]

    # Если ответ ещё не дан — показываем активные кнопки
    if not quiz["answered"]:
        # Создаём кнопки для каждого варианта
        cols = st.columns(1)
        for i, ans in enumerate(answers):
            if cols[0].button(ans, key=f"ans_{i}", use_container_width=True):
                quiz["answered"] = True
                quiz["selected"] = i
                if i == correct_idx:
                    quiz["score"] += 1
                    quiz["feedback"] = "correct"
                else:
                    quiz["feedback"] = "wrong"
                st.rerun()

    # Если ответ дан — показываем обратную связь
    else:
        selected = quiz["selected"]
        # Подсветка: правильный ответ всегда зелёный, неправильный выбор — красный
        for i, ans in enumerate(answers):
            if i == correct_idx:
                st.markdown(f"✅ **{ans}**")  # правильный ответ
            elif i == selected and selected != correct_idx:
                st.markdown(f"❌ ~~{ans}~~")  # ошибочный выбор
            else:
                st.markdown(ans)

        # Текст обратной связи
        if quiz["feedback"] == "correct":
            st.success("Верно!")
        else:
            st.error(f"Неверно. Правильный ответ: **{answers[correct_idx]}**")

        # Кнопка "Далее"
        if st.button("Следующий вопрос ➡️"):
            quiz["current"] += 1
            quiz["answered"] = False
            quiz["selected"] = None
            quiz["feedback"] = None
            st.rerun()

    # Кнопка возврата в меню (всегда доступна)
    st.divider()
    if st.button("← В меню"):
        st.session_state.page = "menu"
        st.rerun()

# -------------------- Режим сопоставления дат --------------------
def show_match():
    match = st.session_state.match
    pairs = match["pairs"]
    offset = match["offset"]
    batch_size = match["batch_size"]

    # Если все пары разгаданы
    if offset >= len(pairs):
        st.balloons()
        st.success("🎉 Все пары найдены! Поздравляем!")
        if st.button("← Вернуться в меню"):
            st.session_state.page = "menu"
            st.rerun()
        return

    # Текущая партия
    batch = pairs[offset:offset + batch_size]
    if not batch:
        # На случай пустой партии — завершаем
        st.success("Вы прошли все блоки!")
        if st.button("← Вернуться в меню"):
            st.session_state.page = "menu"
            st.rerun()
        return

    st.title("Сопоставьте даты и события")
    st.caption(f"Блок {offset // batch_size + 1}. Найдите пары дата ↔ событие")

    # Подготовка данных
    dates = [item["date"] for item in batch]
    events_original = [item["event"] for item in batch]
    # Перемешиваем события на правой стороне
    shuffled_events = events_original.copy()
    random.shuffle(shuffled_events)

    # Создаём две колонки
    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader("Даты")
        for date in dates:
            # Если дата уже сопоставлена — показываем неактивной (зелёной) кнопкой
            if match["matched"].get(date):
                st.button(f"✅ {date}", key=f"d_{date}", disabled=True, use_container_width=True)
            else:
                # Активная кнопка для выбора
                if st.button(date, key=f"d_{date}", use_container_width=True):
                    match["selected_date"] = date
                    # Сброс ошибочной подсветки при новом выборе
                    match["wrong_pair"] = None
                    # Проверяем, если уже выбрано событие, то сразу проверяем пару
                    if match["selected_event"] is not None:
                        check_match()
                    st.rerun()

    with col_right:
        st.subheader("События")
        for event in shuffled_events:
            # Если событие уже сопоставлено — неактивная кнопка
            already_matched = event in match["matched"].values()
            if already_matched:
                st.button(f"✅ {event}", key=f"e_{event}", disabled=True, use_container_width=True)
            else:
                if st.button(event, key=f"e_{event}", use_container_width=True):
                    match["selected_event"] = event
                    match["wrong_pair"] = None
                    if match["selected_date"] is not None:
                        check_match()
                    st.rerun()

    # Отображение выбранных элементов (для ясности)
    if match["selected_date"] or match["selected_event"]:
        st.caption(f"Выбрано: **{match['selected_date'] or '...'}** ↔ **{match['selected_event'] or '...'}**")

    # Обработка неправильной пары (визуальная подсветка)
    if match["wrong_pair"]:
        wrong_date, wrong_event = match["wrong_pair"]
        st.error(f"❌ Неверная пара: {wrong_date} ↔ {wrong_event}")
        # Автоматически сбрасываем подсветку при следующем действии (уже реализовано в кнопках)

    # Кнопка для сброса выбора
    if st.button("Сбросить выбор"):
        match["selected_date"] = None
        match["selected_event"] = None
        match["wrong_pair"] = None
        st.rerun()

    # Возврат в меню
    st.divider()
    if st.button("← В меню"):
        st.session_state.page = "menu"
        st.rerun()

def check_match():
    """Проверяет выбранную пару дата-событие и обновляет состояние игры."""
    match = st.session_state.match
    date = match["selected_date"]
    event = match["selected_event"]
    if not date or not event:
        return

    # Проверка соответствия по исходным данным
    correct = False
    for pair in match["pairs"]:
        if pair["date"] == date and pair["event"] == event:
            correct = True
            break

    if correct:
        # Запоминаем правильную пару
        match["matched"][date] = event
        # Сбрасываем выделение
        match["selected_date"] = None
        match["selected_event"] = None
        match["wrong_pair"] = None

        # Проверяем, закончился ли текущий блок
        batch = match["pairs"][match["offset"]:match["offset"] + match["batch_size"]]
        all_matched = all(pair["date"] in match["matched"] for pair in batch)
        if all_matched:
            # Переход к следующему блоку (после rerun отобразится новый блок)
            match["offset"] += match["batch_size"]
    else:
        # Неправильная пара: запоминаем для сообщения об ошибке
        match["wrong_pair"] = (date, event)
        # Выделение сбрасывать не будем, чтобы пользователь видел, что выбрано;
        # при следующем клике по любой кнопке wrong_pair обнулится.

# -------------------- Главная логика --------------------
def main():
    st.set_page_config(page_title="Обучение", layout="wide")

    # Выбор страницы на основе session_state
    if st.session_state.page == "menu":
        show_menu()
    elif st.session_state.page == "quiz":
        show_quiz()
    elif st.session_state.page == "match":
        show_match()
    else:
        show_menu()

if __name__ == "__main__":
    main()
