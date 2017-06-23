# Как и в любом тесте, подключаем помощник rspec-rails
require 'rails_helper'

# Начинаем описывать функционал, связанный с созданием игры
RSpec.feature 'USER gives wrong answer', type: :feature do

  #создам игру с вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions) }

  before(:each) do
    login_as game_w_questions.user
  end

  scenario 'first answer is wrong' do
    #1 неправильный ответ
    visit game_path(Game.last)
    click_link 'A'
    expect(page).to have_content 'Игра закончена, ваш приз 0 ₽'
  end

  scenario 'after 7 right answers' do
    #1 неправильный ответ после 7 правильных
    visit game_path(Game.last)
    7.times { click_link 'D' }
    click_link 'A'
    expect(page).to have_content 'Игра закончена, ваш приз 1 000 ₽'
  end

  scenario 'after 12 right answers' do
    #1 неправильный ответ после 12 правильных
    visit game_path(Game.last)
    12.times { click_link 'D' }
    click_link 'A'
    expect(page).to have_content 'Игра закончена, ваш приз 32 000 ₽'
  end
end
