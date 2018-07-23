require 'test_helper'

class Kaui::PaymentsControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index, :account_id => @invoice_item.account_id
    assert_response 200
  end

  test 'should list payments' do
    # Test pagination
    get :pagination, :format => :json
    verify_pagination_results!
  end

  test 'should search payments' do
    # Test search
    get :pagination, :search => {:value => 'PENDING'}, :format => :json
    verify_pagination_results!
  end

  test 'should create payments' do
    # Verify we can pre-populate the payment
    get :new, :account_id => @invoice_item.account_id, :invoice_id => @invoice_item.invoice_id
    assert_response 200
    assert_not_nil assigns(:payment)

    # Create the payment
    post :create, :account_id => @invoice_item.account_id, :invoice_payment => {:account_id => @invoice_item.account_id, :target_invoice_id => @invoice_item.invoice_id, :purchased_amount => 10}, :external => 1
    assert_response 302

    # Test pagination
    get :pagination, :format => :json
    verify_pagination_results!(1)
  end

  test 'should expose restful endpoint' do
    get :restful_show, :id => @payment.payment_id
    assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)

    # Search by external_key
    get :restful_show, :id => @payment.payment_external_key
    assert_redirected_to account_payment_path(@payment.account_id, @payment.payment_id)
  end

  test 'should cancel scheduled payment' do
    delete :cancel_scheduled_payment, :id => @payment.payment_id, :account_id => @payment.account_id
    assert_match(/Error deleting payment attempt retry:/, flash[:error])
    expected_response_path = "/accounts/#{@payment.account_id}"
    assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"

    delete :cancel_scheduled_payment, :id => @payment.payment_id, :account_id => @payment.account_id,
           :transaction_external_key => @payment.transactions[0].transaction_external_key
    assert_equal 'Payment attempt retry successfully deleted', flash[:notice]
    expected_response_path = "/accounts/#{@payment.account_id}/payments/#{@payment.payment_id}"
    assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"

  end
end
