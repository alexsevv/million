require 'rails_helper'
# Наш собственный класс с вспомогательными методами
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { FactoryGirl.create(:user) }

  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # Генерим 60 вопросов с 4х запасом по полю level, чтобы проверить работу
      # RANDOM при создании игры.
      generate_questions(60)

      game = nil

      # Создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
        # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
      }.to change(Game, :count).by(1).and(
        # GameQuestion.count +15
        change(GameQuestion, :count).by(15).and(
          # Game.count не должен измениться
          change(Question, :count).by(0)
        )
      )

      # Проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # Проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # Тесты на основную игровую логику
  context 'game mechanics' do
    it 'after true answer' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)

      expect(game_w_questions.current_game_question).not_to eq q

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end
  end

  context '#take_money!' do
    it 'finishes the game' do
      # берем игру и отвечаем на текущий вопрос
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      # взяли деньги
      game_w_questions.take_money!

      prize = game_w_questions.prize
      expect(prize).to be > 0

      # проверяем что закончилась игра и пришли деньги игроку
      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end
  end

  # группа тестов на проверку статуса игры
  context '#status' do
    # перед каждым тестом "завершаем игру"
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  # группа тестов на проверку .answer_current_question!
  context '#answer_current_question!' do
    it 'true answer for the current question' do
      level = game_w_questions.current_level

      expect(game_w_questions.answer_current_question!('d')).to be_truthy
      expect(game_w_questions.current_level).to eq(level + 1)
      expect(game_w_questions.status).to eq(:in_progress)
    end

    it 'false answer for current question' do
      # берем игру и отвечаем на текущий вопрос
      level = game_w_questions.current_level

      #если ответ НЕ правильный
      expect(game_w_questions.answer_current_question!('c')).to be_falsey
      #левел не вырос
      expect(game_w_questions.current_level).to eq(level)
      #статус игры - провален
      expect(game_w_questions.status).to eq(:fail)
    end

    it 'true answer for last question' do
      #ставим текущий уровень максимальным
      game_w_questions.current_level = Question::QUESTION_LEVELS.max

      #проверяем правильный ответ
      expect(game_w_questions.answer_current_question!('d')).to be_truthy
      #статус игры должен быть won
      expect(game_w_questions.status).to eq(:won)
      #денег должно быть на счету больше или равно 1_000_000
      expect(game_w_questions.prize).to be >= 1_000_000
    end

    it 'answer if time is over' do
      game_w_questions.finished_at = Time.now
      game_w_questions.created_at = 1.hour.ago
      expect(game_w_questions.answer_current_question!('d')).to be_falsey
      expect(game_w_questions.status).to eq(:timeout)
    end
  end

  # тестируем метод current_game_question
  context '#current_game_question' do
    it 'returns current unanswered question' do
      expect(game_w_questions.current_game_question.id).to eq(game_w_questions.current_level + 1)
    end
  end

  # тестируем метод cprevious_level
  context '#previous_level' do
    it 'returns the previous level of the game' do
      game_w_questions.current_level = 10
      expect(game_w_questions.previous_level).to eq 9
    end
  end
end
