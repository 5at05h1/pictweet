require 'rails_helper'
describe TweetsController, type: :request do

  before do
    @tweet = FactoryBot.create(:tweet)
  end

  describe "GET #index" do
    it "indexアクションにリクエストすると正常にレスポンスが返ってくる" do 
      get root_path
      expect(response.status).to eq 200
    end
    it "indexアクションにリクエストするとレスポンスに投稿済みのツイートのテキストが存在する" do 
      get root_path
      expect(response.body).to include @tweet.text
    end
    it "indexアクションにリクエストするとレスポンスに投稿済みのツイートの画像URLが存在する" do 
      get root_path
      expect(response.body).to include @tweet.image
    end
    it "indexアクションにリクエストするとレスポンスに投稿検索フォームが存在する" do 
      get root_path
      expect(response.body).to include "投稿を検索する"
    end
  end

  describe "GET #show" do
    it "showアクションにリクエストすると正常にレスポンスが返ってくる" do 
      get tweet_path(@tweet)
      expect(response.status).to eq 200
    end
    it "showアクションにリクエストするとレスポンスに投稿済みのツイートのテキストが存在する" do
      get tweet_path(@tweet)
      expect(response.body).to include @tweet.text 
    end
    it "showアクションにリクエストするとレスポンスに投稿済みのツイートの画像URLが存在する" do
      get tweet_path(@tweet)
      expect(response.body).to include @tweet.image 
    end
    it "showアクションにリクエストするとレスポンスにコメント一覧表示部分が存在する" do 
      get tweet_path(@tweet)
      expect(response.body).to include "＜コメント一覧＞"
    end
  end 
end

RSpec.describe 'ツイート編集', type: :system do
  before do
    @tweet1 = FactoryBot.create(:tweet)
    @tweet2 = FactoryBot.create(:tweet)
  end
  context 'ツイート編集ができるとき' do
    it 'ログインしたユーザーは自分が投稿したツイートの編集ができる' do
      # ツイート1を投稿したユーザーでログインする
      visit new_user_session_path
      fill_in 'Email', with: @tweet1.user.email
      fill_in 'Password', with: @tweet1.user.password
      find('input[name="commit"]').click
      expect(current_path).to eq root_path
      # ツイート1に「編集」ボタンがある
      expect(
        all(".more")[1].hover
      ).to have_link '編集', href: edit_tweet_path(@tweet1)
      # 編集ページへ遷移する
      visit edit_tweet_path(@tweet1)
      # すでに投稿済みの内容がフォームに入っている
      expect(
        find('#tweet_image').value
      ).to eq @tweet1.image
      expect(
        find('#tweet_text').value
      ).to eq @tweet1.text
      # 投稿内容を編集する
      fill_in 'tweet_image', with: "#{@tweet1.image}+編集した画像URL"
      fill_in 'tweet_text', with: "#{@tweet1.text}+編集したテキスト"
      # 編集してもTweetモデルのカウントは変わらない
      expect{
        find('input[name="commit"]').click
      }.to change { Tweet.count }.by(0)
      # 編集完了画面に遷移する
      expect(current_path).to eq tweet_path(@tweet1)
      # 「更新が完了しました」の文字がある
      expect(page).to have_content('更新が完了しました。')
      # トップページに遷移する
      visit root_path
      # トップページには先ほど変更した内容のツイートが存在する（画像）
      expect(page).to have_selector ".content_post[style='background-image: url(#{@tweet1.image}+編集した画像URL);']"
      # トップページには先ほど変更した内容のツイートが存在する（テキスト）
      expect(page).to have_content("#{@tweet1.text}+編集したテキスト")
    end
  end
  context 'ツイート編集ができないとき' do
    it 'ログインしたユーザーは自分以外が投稿したツイートの編集画面には遷移できない' do
      # ツイート1を投稿したユーザーでログインする
      visit new_user_session_path
      fill_in 'Email', with: @tweet1.user.email
      fill_in 'Password', with: @tweet1.user.password
      find('input[name="commit"]').click
      expect(current_path).to eq root_path
      # ツイート2に「編集」ボタンがない
      expect(
        all(".more")[0].hover
      ).to have_no_link '編集', href: edit_tweet_path(@tweet2)
    end
    it 'ログインしていないとツイートの編集画面には遷移できない' do
      # トップページにいる
      visit root_path
      # ツイート1に「編集」ボタンがない
      expect(
        all(".more")[1].hover
      ).to have_no_link '編集', href: edit_tweet_path(@tweet1)
      # ツイート2に「編集」ボタンがない
      expect(
        all(".more")[0].hover
      ).to have_no_link '編集', href: edit_tweet_path(@tweet2)
    end
  end
end

RSpec.describe 'ツイート削除', type: :system do
  before do
    @tweet1 = FactoryBot.create(:tweet)
    @tweet2 = FactoryBot.create(:tweet)
  end
  context 'ツイート削除ができるとき' do
    it 'ログインしたユーザーは自らが投稿したツイートの削除ができる' do
      # ツイート1を投稿したユーザーでログインする
      visit new_user_session_path
      fill_in 'Email', with: @tweet1.user.email
      fill_in 'Password', with: @tweet1.user.password
      find('input[name="commit"]').click
      expect(current_path).to eq root_path
      # ツイート1に「削除」ボタンがある
      expect(
        all(".more")[1].hover
      ).to have_link '削除', href: tweet_path(@tweet1)
      # 投稿を削除するとレコードの数が1減る
      expect{
        all(".more")[1].hover.find_link('削除', href: tweet_path(@tweet1)).click
      }.to change { Tweet.count }.by(-1)
      # 削除完了画面に遷移する
      expect(current_path).to eq tweet_path(@tweet1)
      # 「削除が完了しました」の文字がある
      expect(page).to have_content('削除が完了しました。')
      # トップページに遷移する
      visit root_path
      # トップページにはツイート1の内容が存在しない（画像）
      expect(page).to have_no_selector ".content_post[style='background-image: url(#{@tweet1.image});']"
      # トップページにはツイート1の内容が存在しない（テキスト）
      expect(page).to have_no_content("#{@tweet1.text}")
    end
  end
  context 'ツイート削除ができないとき' do
    it 'ログインしたユーザーは自分以外が投稿したツイートの削除ができない' do
      # ツイート1を投稿したユーザーでログインする
      visit new_user_session_path
      fill_in 'Email', with: @tweet1.user.email
      fill_in 'Password', with: @tweet1.user.password
      find('input[name="commit"]').click
      expect(current_path).to eq root_path
      # ツイート2に「削除」ボタンが無い
      expect(
        all(".more")[0].hover
      ).to have_no_link '削除', href: tweet_path(@tweet2)
    end
    it 'ログインしていないとツイートの削除ボタンがない' do
      # トップページに移動する
      visit root_path
      # ツイート1に「削除」ボタンが無い
      expect(
        all(".more")[1].hover
      ).to have_no_link '削除', href: tweet_path(@tweet1)
      # ツイート2に「削除」ボタンが無い
      expect(
        all(".more")[0].hover
      ).to have_no_link '削除', href: tweet_path(@tweet2)
    end
  end
end

RSpec.describe 'ツイート詳細', type: :system do
  before do
    @tweet = FactoryBot.create(:tweet)
  end
  it 'ログインしたユーザーはツイート詳細ページに遷移してコメント投稿欄が表示される' do
    # ログインする
    visit new_user_session_path
    fill_in 'Email', with: @tweet.user.email
    fill_in 'Password', with: @tweet.user.password
    find('input[name="commit"]').click
    expect(current_path).to eq root_path
    # ツイートに「詳細」ボタンがある
    expect(
      all(".more")[0].hover
    ).to have_link '詳細', href: tweet_path(@tweet)
    # 詳細ページに遷移する
    visit tweet_path(@tweet)
    # 詳細ページにツイートの内容が含まれている
    expect(page).to have_selector ".content_post[style='background-image: url(#{@tweet.image});']"
    expect(page).to have_content("#{@tweet.text}")
    # コメント用のフォームが存在する
    expect(page).to have_selector 'form'
  end
  it 'ログインしていない状態でツイート詳細ページに遷移できるもののコメント投稿欄が表示されない' do
    # トップページに移動する
    visit root_path
    # ツイートに「詳細」ボタンがある
    expect(
      all(".more")[0].hover
    ).to have_link '詳細', href: tweet_path(@tweet)
    # 詳細ページに遷移する
    visit tweet_path(@tweet)
    # 詳細ページにツイートの内容が含まれている
    expect(page).to have_selector ".content_post[style='background-image: url(#{@tweet.image});']"
    expect(page).to have_content("#{@tweet.text}")
    # フォームが存在しないことを確認する
    expect(page).to have_no_selector 'form'
    # 「コメントの投稿には新規登録/ログインが必要です」が表示されていることを確認する
    expect(page).to have_content 'コメントの投稿には新規登録/ログインが必要です'
  end
end