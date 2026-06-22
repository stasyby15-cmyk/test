import tkinter as tk
from tkinter import messagebox
from tkinter import ttk
import random

def clear_window(root):
    for widget in root.winfo_children():
        widget.destroy()

class MainMenu:

    def __init__(self, root):

        self.root = root

        clear_window(root)

        frame = tk.Frame(
            root,
            bg="#1e1e2f"
        )
        frame.pack(fill="both", expand=True)

        title = tk.Label(
            frame,
            text="Выберите режим обучения",
            font=("Arial", 22, "bold"),
            bg="#1e1e2f",
            fg="white"
        )
        title.pack(pady=50)

        test_btn = tk.Button(
            frame,
            text="📝 Тесты",
            width=25,
            height=2,
            font=("Arial", 14),
            command=self.start_quiz
        )
        test_btn.pack(pady=15)

        match_btn = tk.Button(
            frame,
            text="📅 Даты и события",
            width=25,
            height=2,
            font=("Arial", 14),
            command=self.start_match
        )
        match_btn.pack(pady=15)

        



    def start_quiz(self):

        clear_window(self.root)

        questions = load_questions("questions.json")

        QuizApp(self.root, questions)

    def start_match(self):

        clear_window(self.root)

        with open(
            "dates.json",
            "r",
            encoding="utf-8"
        ) as f:

            pairs = json.load(f)

        MatchMode(self.root, pairs)


class MatchMode:

    def __init__(self, root, pairs):

        self.root = root
        self.pairs = pairs

        self.batch_size = 10
        self.offset = 0
        
        self.main_frame = tk.Frame(
            root,
            bg="#1e1e2f"
        )
        self.main_frame.pack(fill="both", expand=True)

        title = tk.Label(
            self.main_frame,
            text="Сопоставьте даты и события",
            font=("Arial", 20, "bold"),
            bg="#1e1e2f",
            fg="white"
        )
        title.pack(pady=20)

        self.status_label = tk.Label(
            self.main_frame,
            text="",
            font=("Arial", 12),
            bg="#1e1e2f",
            fg="white"
        )
        self.status_label.pack(pady=5)
        
        self.game_frame = tk.Frame(self.main_frame, bg="#1e1e2f")
        self.game_frame.pack(fill="both", expand=True, padx=20, pady=10)
        self.game_frame.pack_propagate(False)

        self.content = tk.Frame(self.game_frame, bg="#1e1e2f")
        self.content.pack(fill="both", expand=True)


        self.correct_matches = 0
        self.total_matches = len(pairs)

        self.selected_date = None
        self.selected_event = None

        self.date_buttons = {}
        self.event_buttons = {}


        self.build_board()


        menu_btn = tk.Button(
            self.main_frame,
            text="← В меню",
            command=self.back_to_menu
        )
        menu_btn.pack(anchor="nw", padx=10, pady=10)




    def build_board(self):
        if hasattr(self, "left_frame"):
            self.left_frame.destroy()

        if hasattr(self, "right_frame"):
            self.right_frame.destroy()

        # очищаем старые элементы
        for widget in self.content.winfo_children():
            widget.destroy()

        self.left_frame = tk.Frame(self.content, bg="#1e1e2f")
        self.left_frame.pack(side="left", fill="both", expand=True, padx=30)

        self.right_frame = tk.Frame(self.content, bg="#1e1e2f")
        self.right_frame.pack(side="right", fill="both", expand=True, padx=30)
        
        batch = self.pairs[self.offset:self.offset + self.batch_size]

        dates = batch.copy()
        events = [x["event"] for x in batch]

        random.shuffle(events)

        self.date_buttons = {}
        self.event_buttons = {}

        for item in dates:
            btn = tk.Button(
                self.left_frame,
                text=item["date"],
                font=("Arial", 13),
                width=28,
                height=2,
                wraplength=250,
                command=lambda d=item["date"]: self.select_date(d)
            )
            btn.pack(pady=6)
            self.date_buttons[item["date"]] = btn

        for event in events:
            btn = tk.Button(
                self.right_frame,
                text=event,
                font=("Arial", 13),
                width=45,
                height=2,
                wraplength=400,
                justify="center",
                command=lambda e=event: self.select_event(e)
            )
            btn.pack(pady=6)
            self.event_buttons[event] = btn

    def select_date(self, date):

        self.selected_date = date

        for btn in self.date_buttons.values():
            btn.config(bg="SystemButtonFace")

        self.date_buttons[date].config(bg="#6c63ff")

        self.check_match()

    def select_event(self, event):

        self.selected_event = event

        for btn in self.event_buttons.values():
            btn.config(bg="SystemButtonFace")

        self.event_buttons[event].config(bg="#6c63ff")

        self.check_match()

    def check_match(self):

        if self.selected_date is None:
            return

        if self.selected_event is None:
            return

        correct = False

        for pair in self.pairs:

            if (
                pair["date"] == self.selected_date
                and pair["event"] == self.selected_event
            ):
                correct = True
                break

        if correct:

            self.date_buttons[self.selected_date].config(
                bg="green",
                state="disabled"
            )

            self.event_buttons[self.selected_event].config(
                bg="green",
                state="disabled"
            )

            self.root.after(
                500,
                lambda: self.remove_pair(
                    self.selected_date,
                    self.selected_event
                )
            )

            self.correct_matches += 1

            if self.correct_matches == len(self.pairs):
                messagebox.showinfo("Готово", "Все пары найдены!")
                return

            if self.correct_matches % self.batch_size == 0:
                self.root.after(800, self.next_batch)

        else:

            self.date_buttons[self.selected_date].config(bg="red")
            self.event_buttons[self.selected_event].config(bg="red")

            self.root.after(
                800,
                lambda: self.reset_colors(
                    self.selected_date,
                    self.selected_event
                )
            )

        self.selected_date = None
        self.selected_event = None

    def remove_pair(self, date, event):

        self.date_buttons[date].pack_forget()
        self.event_buttons[event].pack_forget()

    def reset_colors(self, date, event):

        if date in self.date_buttons:
            self.date_buttons[date].config(bg="SystemButtonFace")

        if event in self.event_buttons:
            self.event_buttons[event].config(bg="SystemButtonFace")
    
    def back_to_menu(self):
        clear_window(self.root)
        MainMenu(self.root)
    
    def next_batch(self):
        self.offset += self.batch_size

        if self.offset >= len(self.pairs):
            messagebox.showinfo("Готово", "Вы прошли все блоки!")
            return

        self.build_board()

class QuizApp:
    def __init__(self, root, questions):
        self.root = root
        self.root.title("Quiz App")
        self.root.geometry("800x500")
        self.root.configure(bg="#1e1e2f")

        self.questions = questions
        self.current_question = 0
        self.score = 0

        # Прогресс
        self.progress_label = tk.Label(
            root,
            text="",
            font=("Arial", 11),
            bg="#1e1e2f",
            fg="white"
        )
        self.progress_label.pack(pady=(10, 0))

        self.progress = ttk.Progressbar(
            root,
            length=600,
            mode="determinate"
        )
        self.progress.pack(pady=(5, 15))

        self.progress["maximum"] = len(self.questions)



        # 🎯 КАРТОЧКА ВОПРОСА
        self.card = tk.Frame(
            root,
            bg="#2a2a40",
            padx=20,
            pady=20
        )
        self.card.pack(pady=30, fill="x", padx=50)

        self.question_label = tk.Label(
            self.card,
            text="",
            font=("Arial", 18, "bold"),
            bg="#2a2a40",
            fg="white",
            wraplength=700,
            justify="center"
        )
        self.question_label.pack()

        self.result_label = tk.Label(
            self.card,
            text="",
            font=("Arial", 12, "bold"),
            bg="#2a2a40",
            fg="white"
        )
        self.result_label.pack(pady=10)

        # 🎯 КНОПКИ ОТВЕТОВ
        self.answer_buttons = []
        self.MAX_ANSWERS = 5

        self.btn_frame = tk.Frame(root, bg="#1e1e2f")
        self.btn_frame.pack(pady=10)

        for i in range(self.MAX_ANSWERS):
            btn = tk.Button(
                self.btn_frame,
                text="",
                width=70,
                height=3,
                wraplength=700,
                justify="center",
                font=("Arial", 12),
                bg="#3b3b5c",
                fg="white",
                activebackground="#6c63ff",
                activeforeground="white",
                bd=0,
                command=lambda idx=i: self.check_answer(idx)
            )
            btn.pack(pady=5)

            # hover эффект
            btn.bind("<Enter>", lambda e, b=btn: b.config(bg="#5757a3"))
            btn.bind("<Leave>", lambda e, b=btn: b.config(bg="#3b3b5c"))

            self.answer_buttons.append(btn)

        menu_btn = tk.Button(
            root,
            text="← В меню",
            command=self.back_to_menu
        )
        menu_btn.pack(anchor="nw", padx=10, pady=10)

        # запуск
        self.root.after(100, self.load_question)

    def load_question(self):
        if self.current_question >= len(self.questions):
           
           # заполняем прогресс-бар на 100%
            self.progress["value"] = len(self.questions)
            
            messagebox.showinfo(
                "Готово",
                f"Результат: {self.score}/{len(self.questions)}"
            )
            self.root.quit()
            return

        q = self.questions[self.current_question]

        self.progress["value"] = self.current_question

        remaining = len(self.questions) - self.current_question

        self.progress_label.config(
            text=f"Вопрос {self.current_question + 1} из {len(self.questions)} | Осталось: {remaining}"
        )

        self.question_label.config(
            text=f"Вопрос {self.current_question + 1}/{len(self.questions)}\n\n{q['question']}"
        )

        self.root.update_idletasks()

        self.result_label.config(text="")

        answers = q["answers"]

        for i, btn in enumerate(self.answer_buttons):
            if i < len(answers):
                btn.config(
                    text=answers[i],
                    state="normal",
                    bg="#3b3b5c"
                )
                btn.pack(pady=5)
            else:
                btn.pack_forget()

    def back_to_menu(self):
        clear_window(self.root)
        MainMenu(self.root)

    def check_answer(self, selected_index):
        q = self.questions[self.current_question]

        correct_index = q["correct"]
        correct_text = q["answers"][correct_index]

        # блокируем кнопки
        for btn in self.answer_buttons:
            btn.config(state="disabled")

        # подсветка правильного ответа
        self.answer_buttons[correct_index].config(bg="green")

        if selected_index == correct_index:
            self.score += 1

            self.result_label.config(
                text="✅ Верно!",
                fg="#4CAF50"
            )
        else:
            self.answer_buttons[selected_index].config(bg="red")

            self.result_label.config(
                text=f"❌ Неверно\nПравильный ответ: {correct_text}",
                fg="#FF6B6B"
            )

        self.current_question += 1

        # задержка 2 секунды
        self.root.after(2000, self.load_question)

    def flash_result(self, color):
        original = self.question_label.cget("bg")

        self.question_label.config(bg=color)
        self.root.after(200, lambda: self.question_label.config(bg=original))

import json

def load_questions(filename):
    with open(filename, "r", encoding="utf-8") as f:
        return json.load(f)


if __name__ == "__main__":
    root = tk.Tk()
    
    MainMenu(root)

    root.mainloop()
