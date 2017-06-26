require 'rails_helper'

# Тест на шаблон users/show.html.erb

RSpec.describe 'users/show', type: :view do

  context 'for current user' do
    before(:each) do
      user =  FactoryGirl.build_stubbed(:user, name: 'Alex')
      assign(:user, user)

      assign(:games, [
        FactoryGirl.build_stubbed(:game_with_questions, created_at: '12 июня, 12:45'),
        FactoryGirl.build_stubbed(:game_with_questions, created_at: '12 июня, 13:55'),
        FactoryGirl.build_stubbed(:game_with_questions, created_at: '19 июня, 14:59')
      ])

      allow(view).to receive(:current_user).and_return(user)

      render
    end

    # Текущий пользователь видит свое имя
    it 'renders user name' do
      expect(rendered).to match 'Alex'
    end

    # Текущий пользователь видит кнопку смены пароля
    it 'renders change password and name for current user' do
      expect(rendered).to match 'Сменить имя и пароль'
    end

    # Текущий пользователь видит фрагмент игры
    it 'renders fragment game' do
      expect(rendered).to match '50/50'
      #проверим, что игры создалась в указанное время
      expect(rendered).to match '12 июня, 12:45'
      expect(rendered).to match '12 июня, 13:55'
      expect(rendered).to match '19 июня, 14:59'
    end
  end

  context 'for not current user' do
    before(:each) do
      user =  FactoryGirl.build_stubbed(:user, name: 'Alex')
      assign(:user, user)

      assign(:games, [
        FactoryGirl.build_stubbed(:game_with_questions)
      ])

      allow(view).to receive(:current_user).and_return(nil)

      render
    end

    # Не текущий пользователь НЕ видит кнопку смены пароля
    it 'renders change password and name for current user' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end
end
