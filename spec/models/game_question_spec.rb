require 'rails_helper'

RSpec.describe GameQuestion, type: :model do

  let(:game_question) { FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  context 'game status' do
    it "correct .variants" do
      expect(game_question.variants).to eq({'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3
                                          })
    end

    it "correct .answer_correct?" do
      expect(game_question.answer_correct?('b')).to be_truthy
    end

    # тест на наличие методов делегатов level и text
    it 'correct .level & .text delegates' do
      expect(game_question.text).to eq(game_question.question.text)
      expect(game_question.level).to eq(game_question.question.level)
    end

    #так как мы проставили "1" к варианту b при создании game_question,
    #то вариант b должен быть правильным
    it 'correct .correct_answer_key' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end
end
