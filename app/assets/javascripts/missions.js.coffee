# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

ready = ->

  # 進行中の旅があるか確認
  if $('#user_info').data('progress-trip') == 1
    $('#before_start_app').css('display', 'none')
    $('#wrap').css('opacity', 1)
  else
    # 旅が進行中じゃない場合
    if $(location).attr('pathname') == "/missions/index"
      $('#before_start_app').css('display', '')
      $('#wrap').css('opacity', 0.25)
      $('#getting_start_app').click ->
        # 旅情報登録APIの追加処理
        $.ajax
          type: 'POST'
          url: '/missions/trip_infomations_api'
          dataType: 'json'
          data:
            user_no: $('#user_info').data('user-no')
          success: (data, status, xhr) ->
            $('#before_start_app').css('display', 'none')
            $('#wrap').css('opacity', 1)
          error: (xhr, status, error) -> 
            alert 'ネットワーク障害が発生している可能性があります。\nしばらく時間を置いて再度アクセスして下さい。'
            # デバッグ作業のため追加しているけど後で消します ↓
            $('#before_start_app').css('display', 'none')
            $('#wrap').css('opacity', 1)
            #####
          complete: (xhr, status) -> 

  # 現在の駅の表示を強調する
  current_station_no = $('#station_info').data('current-station-no')
  if current_station_no != undefined
    current_station = $('.enable-station').get(current_station_no - 1)
    $(current_station).parent().css('color', 'orange')

    x=$(current_station).offset().left - 12; 
    y=$(current_station).offset().top - 10;
    # 画像を表示す
    $('#img_user').css('left', x);
    $('#img_user').css('top', y);

  # 目的地の駅の表示を強調する
  next_station_no = $('#station_info').data('next-station-no')
  if next_station_no != undefined && next_station_no > 0
    next_station = $('.enable-station').get(next_station_no - 1)
    $(next_station).parent().css('color', 'red')
    x_next=$(next_station).offset().left - 12;
    y_next=$(next_station).offset().top - 10;
    $('#img_user').css('left', x_next);
    $('#img_user').css('top', y_next);
  else
    $('#img_user').css('left', x);
    $('#img_user').css('top', y);   

  # サイコロを振るボタンのイベント処理
  $('#dice_btn').click ->

    img = $('#dice_img');

    # サイコロストップ 
    if img.hasClass('ready-dice')
      $('#dice_div').css('display', '') 
      c_station_no = $('#station_info').data('current-station-no')
      dice_value = eval(Math.floor(Math.random() * 3) + 1)

      # ajaxで非同期に決定した駅のミッション一覧情報を取得する
      $.ajax
        type: 'GET'
        url: '/missions/mission_list_api'
        dataType: 'html'
        data: 
          'dice_no': dice_value
        success: (data, status, xhr) ->
          # 取得した情報で$('#dynamic_div')領域を更新する
          mission_div = $(data).find('#mission_data')
          $('#mission_data').remove()
          $('#mission_div').prepend(mission_div)
        error: (xhr, status, error) -> 
        complete: (xhr, status) -> 

      dice_stop_anime_gif = "/assets/dice/" + "21_0.1_" + dice_value + ".gif";
      # select_dice_img_path = "/assets/dice/" + "dice_" + dice_value + ".png"
      img.attr('src', dice_stop_anime_gif)
      img.toggleClass('ready-dice');
      img.toggleClass('show-mission')
      $('#dice_btn').attr("disabled", true)
      $('#station_info').data('target-station-no', dice_value+c_station_no)

      setTimeout ->
        $('#dice_btn').text('マスを進む')
        $('#dice_btn').attr("disabled", false)
        $('#operation-message').text('マスを進んでください')
      , 4500
      return

    # ミッション一覧を表示 
    if img.hasClass('show-mission') 

      $('#dice_btn').attr("disabled", true)
      # 現在の位置
      c_station_no = $('#station_info').data('current-station-no')
      c_station = $('.enable-station').get(c_station_no - 1)
      x_current=$(c_station).offset().left - 12;
      y_current=$(c_station).offset().top - 10;

      # 次の目的地駅
      target_station_no = $('#station_info').data('target-station-no')
      if target_station_no > 10
        target_station_no = 10
      target_station = $('.enable-station').get(target_station_no - 1)
      x_target=$(target_station).offset().left - 12;
      $(target_station).parent().css('color', 'red')

      # 画像を表示す
      for i in [0..(x_target-x_current)*50]
          loop_target(i,x_current,target_station);

      setTimeout ->
           $('#img_user').css('transform', 'rotate(0deg)')
           $(target_station).parent().css('color', 'red') 
           $('#dice_btn').css('display', 'none')
           $('#operation-message').text('ミッションを一つ選んでください')
           $('#dice_btn').attr("disabled", '')
           $('#mission_div').toggleClass('display-none-style')
           $('#dice_div').css('display', 'none')
      , (x_target-x_current)*50+500

  # ミッションをランダムに決定する処理 
  $('#random_btn').on 'click', -> 
    # 前回に選択していたミッションの色を戻す
    $('.select-mission').toggleClass('select-mission')

    # ミッションの一覧の数を取得
    total_mission = $('.mission-info')
    # ランダムでミッション一覧から番号を選ぶ
    mission_no = eval(Math.floor(Math.random() * total_mission.length) + 1)
    # ミッションを選んだエフェクトを付ける
    $(total_mission.get(mission_no - 1)).find('.thumbnail').toggleClass('select-mission')

    # スマホでの表示用に時間を遅らせる
    setTimeout (->
      if confirm('このミッションの詳細を見ますか？')
        nowLoadingStart();
        data = $(total_mission.get(mission_no - 1)).data()

        next_page =
         '/missions/show?' + 'station_no=' + data.stationNo + '&mission_no=' + data.missionNo
        location.href = next_page
      else
        # ミッションを選択し直す
        $('.select-mission').toggleClass('select-mission')
      return
    ), "500"

  # 地図の表示をツールチップで実装する
  $("#map_btn").darkTooltip
    animation: "fadeIn"
    gravity: "left"
    theme: "light"
    trigger: "click"

  $(".navbar-toggle").on 'click', ->

    $('#img_user').css('display', 'none')

    setTimeout ->
      # 現在の位置
      c_station_move_no = $('#station_info').data('current-station-no')
      c_station_move = $('.enable-station').get(c_station_move_no - 1)
      y_move=$(c_station_move).offset().top - 10;
      $('#img_user').css('top', y_move)
      $('#img_user').css('display', '')
    , 350

  loop_target = (i,x_current,target_station) ->

        setTimeout ->
          $('#img_user').css('left', x_current+i*0.02)
          if i%1000 == 0
            $(target_station).parent().css('color', 'red')
            $('#img_user').css('transform', 'rotate(5deg)')
          if i%1000 == 250
            $('#img_user').css('transform', 'rotate(0deg)')
          else if i%1000 == 500
            $(target_station).parent().css('color', 'black')
            $('#img_user').css('transform', 'rotate(-5deg)')
          if i%1000 == 750
            $('#img_user').css('transform', 'rotate(0deg)')
        , 1*i
        return

  $(document).on 'click', '.loading', ->
    nowLoadingStart()
    return

  $('.loading-confirm').on 'confirm:complete', (e, answer) ->
    if answer
      nowLoadingStart()

# Turbolinksによるajaxページ遷移のため再度イベントを設定
$(document).ready(ready)
$(document).on('page:load', ready)
