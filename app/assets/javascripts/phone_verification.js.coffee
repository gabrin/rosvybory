class PhoneVerification
  constructor: ->
    if @confirmed()
      @success_message()
      $("#user_app_phone").attr('readonly', 'readonly')
    else
      @init_form()
      @init_recaptcha()
      @init_controls()

  confirmed: =>
    $("#user_app_phone").data('confirmed')

  init_form: =>
    $('#user_app_phone_input .controls').append('
    <input type="button" id="verification_start_button" class="btn btn-warning" value="Подтвердить">
    <div id="recaptcha"></div>
    <div id="verification_controls">
      <input type="text" id="verification_code" class="input-small" placeholder="Код из SMS"/>
      <input type="button" name="" class="btn btn-warning" id="verification_confirm_button" value="Отправить"/>
    </div>')

  init_recaptcha: =>
    if (typeof(Recaptcha) != "undefined")
      Recaptcha.focus_response_field = (->)
      Recaptcha.create(gon.recaptcha_key, "recaptcha", {
        theme: "clean",
        callback: Recaptcha.focus_response_field
      })

  init_controls: =>
    $('#verification_start_button').on 'click', (e)=>
      e.preventDefault()
      $(this).attr('disabled', 'disabled')
      number = $('#user_app_phone').attr('readonly', 'readonly').val()
      @start_verification(number)

    $('#verification_confirm_button').on 'click', (e)=>
      e.preventDefault()
      $(this).attr('disabled', 'disabled')
      code = $('#verification_code').val()
      @complete_verification(code)

  start_verification: (number)=>
    params = {phone_number: number}
    if (typeof(Recaptcha) != "undefined")
      params.recaptcha_challenge_field = Recaptcha.get_challenge()
      params.recaptcha_response_field = Recaptcha.get_response()
    $.ajax
      url: '/verifications'
      data: $.param(params)
      method: 'POST'
      success: (data)=>
        @on_success(data)
      error: =>
        @on_error()

  complete_verification: (code)=>
    $.ajax
      url: '/verifications/confirm'
      data: $.param(verification_code: code)
      method: 'POST'
      success: (data)=>
        if data.success
          $('#verification_controls').hide()
          @hide_error()
          @success_message()
        else
          @error_message('Неправильный код подтверждения')
          $('#verification_confirm_button').removeAttr('disabled')

  on_success: (data)=>
    if data.success
      if data.simulation
        alert "Включён режим симуляции, для подтверждения подойдёт любой код"
      $('#verification_start_button').hide()
      $('#verification_controls').css('display', 'inline-block')
      @hide_error()
      if (typeof(Recaptcha) != "undefined")
        Recaptcha.destroy()
    if data.error
      @error_message(data.error)
      @restore()

  on_error: =>
    alert('Ошибка отправки запроса')
    @restore()

  restore: =>
#    Recaptcha.reload("t")
    $('#user_app_phone').removeAttr('readonly')

  success_message: =>
    span = $(' <span class="help-inline label label-success"></span>')
    $("#user_app_phone_input .controls").append(span)
    span.html('Успешно подтвержден')

    # HOOK HERE чтобы задействовать кнопку для отправки формы

  error_message: (message)=>
    span = $("#user_app_phone_input span.help-inline")
    if span.length == 0
      span = $('<span class="help-inline label label-warning"></span>')
      $("#user_app_phone_input .controls").append(span)
    span.html(message)

  hide_error: =>
    $("#user_app_phone_input span.help-inline").hide()


window.PhoneVerification = PhoneVerification
