# Как и в любом тесте, подключаем помощник rspec-rails
require 'rails_helper'

# Начинаем описывать функционал, связанный с созданием игры
RSpec.feature 'USER views rating', type: :feature do

  let!(:users) {[
    FactoryGirl.create(:user, name: 'Саша', balance: 1000000),
    FactoryGirl.create(:user, name: 'Маша', balance: 900000),
    FactoryGirl.create(:user, name: 'Паша', balance: 100)
  ]}

  # Сценарий успешного просмотра рейтинга
  scenario 'successfully' do
    # Заходим на главную
    visit '/'

    # Ожидаем, что на экране списсок игроков и их балансы
    expect(page).to have_content '1 000 000'
    expect(page).to have_content '900 000'
    expect(page).to have_content '100'
    expect(page).to have_content 'Саша'
    expect(page).to have_content 'Маша'
    expect(page).to have_content 'Паша'

    #проверим правильный порядок отображения пользователей в рейтинге
    expect(page.body).to match /1 000 000.*900 000.*100/m
    expect(page.body).to match /Саша.*Маша.*Паша/m
  end
end
