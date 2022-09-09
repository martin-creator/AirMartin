class UsersController < ApplicationController
    before_action :authenticate_user!, except: [:show]

    def show
        @user = User.find(params[:id])
        @rooms = @user.rooms

        #Displays all the guest reviews to host(if this user is a host)
        @guest_reviews =  Review.where(type: "GuestReview", host_id: @user.id )

        #Displays all the host reviews to host(if this user is a guest)
        @host_reviews =  Review.where(type: "HostReview", guest_id: @user.id )
    end

    def update_phone_number
        current_user.update_attributes(user_params)
        current_user.generate_pin
        current_user.send_pin

        redirect_to edit_user_registration_path, notice: "Saved..."

    rescue Exception => e
        redirect_to edit_user_registration_path, alert: "#{e.message}"

    end

    def verify_phone_number
        current_user.verify_pin(params[:user][:pin])

        if current_user.phone_verified
            flash[:notice] = "Your phone number is verified"
        else
            flash[:alert] = "Cannot verify your phone number"
        end

    rescue Exception => e
        redirect_to edit_user_registration_path, alert: "#{e.message}"

    end

    def payment
    end


    def add_card
        if current_user.stripe_id.blank?
          customer = Stripe::Customer.create({
            email: current_user.email,
            source: params[:stripeToken]
        })
            
          current_user.stripe_id = customer.id
          current_user.save

          
           # Add Credit Card to Stripe
            Stripe::Customer.create_source(customer.id, source: params[:stripeToken])
          #customer.sources.create(source: params[:stripeToken])
        else
          customer = Stripe::Customer.retrieve(current_user.stripe_id)
          #Stripe::Customer.update()
          #Stripe::Source.update({params[:stripeToken]})
          #customer.source =  {source: params[:stripeToken]} #params[:stripeToken]
          customer.save
        end


        flash[:notice] = "Your card is saved."
        redirect_to payment_method_path
    rescue Stripe::CardError => e 
        flash[:alert] = e.message
        redirect_to payment_method_path
     end


    private

        def user_params
            params.require(:user).permit(:phone_number, :pin)
        end
end