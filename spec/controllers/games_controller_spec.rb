require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do

  #jбычный пользователь
  let(:user) { FactoryGirl.create(:user) }
  #админ
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  #игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  context 'anon' do
    it 'kick from #show' do
      get :show, id: game_w_questions.id

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    #анонимный юзер не может создавать игру
    it 'kick from #create' do
      generate_questions(60)
      post :create
      game = assigns(:game)

      expect(game).to be_nil
      expect(flash[:alert]).to be
    end
  end

  #группа тестов на экшены контроллера, доступных залогиненным юзерам
  context 'Usual user' do

    before(:each) do
      sign_in user
    end

    it 'creates game' do
      generate_questions(60)
      post :create
      game = assigns(:game)

      #проверим состояние этой игры
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response).to redirect_to game_path(game)
      expect(flash[:notice]).to be
    end

    it '#show game' do
      get :show, id: game_w_questions.id
      game = assigns(:game) #вытаскиваем из контроллера поле @game
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq(200)#должен быть ответ HTTP 200
      expect(response).to render_template('show')
    end

    it 'answer correct' do
      put :answer, id:game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key

      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(user))
      expect(flash.empty?).to be_truthy #удачный ответ не заполняет flash
    end

    it 'answer incorrect' do
      put :answer, id:game_w_questions.id, letter: 'z'

      game = assigns(:game)

      expect(flash[:alert]).to be #ошибка есть
      expect(game.finished?).to be_truthy #игра закончилась
      expect(game.current_level).to be == 0 #левел не поднялся
      expect(response).to redirect_to user_path(user) #редиректнуло на страницу юзера
    end

    it '#show alien game' do
      # создаем новую игру, юзер не прописан, будет создан фабрикой новый
      alien_game = FactoryGirl.create(:game_with_questions)

      # пробуем зайти на эту игру текущий залогиненным user
      get :show, id: alien_game.id

      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end

    # юзер берет деньги
    it 'takes money' do
      # вручную поднимем уровень вопроса до выигрыша 200
      game_w_questions.update_attribute(:current_level, 2)

      put :take_money, id: game_w_questions.id
      game = assigns(:game)
      expect(game.finished?).to be_truthy
      expect(game.prize).to eq(200)

      # пользователь изменился в базе, надо в коде перезагрузить!
      user.reload
      expect(user.balance).to eq(200)

      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end

    # юзер пытается создать новую игру, не закончив старую
    it 'try to create second game' do
      # убедились что есть игра в работе
      expect(game_w_questions.finished?).to be_falsey

      # отправляем запрос на создание, убеждаемся что новых Game не создалось
      expect { post :create }.to change(Game, :count).by(0)

      game = assigns(:game) # вытаскиваем из контроллера поле @game
      expect(game).to be_nil

      # и редирект на страницу старой игры
      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end



  end
end
