RailsAdmin.config do |config|

  ### Popular gems integration

  ## == Devise ==
  # config.authenticate_with do
  #   warden.authenticate! scope: :user
  # end
  # config.current_user_method(&:current_user)

  ## == Cancan ==
  # config.authorize_with :cancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end


  config.main_app_name = 'Kindred Britain'

  # Disable .js form validation
  config.browser_validations = false

  config.included_models = [
    Indiv,
    Event,
    Particip,
    Occu,
    Place,
  ]

  config.model 'Indiv' do
    list do
      field :indiv_id
      field :fullname
      # field :birthyear
      # field :deathyear
      sort_by :surn
      field :surn do
        # hide
        sort_reverse false
      end
    end

    edit do
      # exclude_fields :indiv_id, :recno, :reli, :fams, :famc, :sim20, :birt, :deat,
      # :perioddist, :search_names, :perioddist_new, :chantext, :chandate,
      # :diedyoung

      field :fullname do
        label "Full name"
      end
      field :givn do
        label "Given name"
      end
      field :surn do
        label "Surname"
        help "without prefix; add below"
      end
      field :spfx do
        label "surname prefix"
        help "e.g. 'von', 'de'"
      end
      field :marnm do
        label "Married name"
      end
      field :npfx do
        label "Name prefix"
      end
      field :nsfx do
        label "Name suffix"
      end
      # field :birthdate do
      #   label "Birth date"
      # end
      # field :birthyear do
      #   label "Birth year (certain)"
      #   help "Enter certain OR approx. not both"
      # end
      # field :birth_abt do
      #   label "Birth year (approx.)"
      # end
      # field :best do
      #   label "Birth year (machine estimated; don't enter for new records)"
      #   help ""
      # end
      # field :deathdate do
      #   label "Death date"
      # end
      # field :deathyear do
      #   label "Death year (certain)"
      #   help "Enter certain OR approx. not both"
      # end
      # field :death_abt do
      #   label "Death year (approx.)"
      # end
      # field :dest do
      #   label "Death year (machine estimated; don't enter for new)"
      #   help ""
      # end
      field :odnb_id do
        label "ODNB id"
        help "ODNB id if in, empty if not"
      end
      field :occus do
        label "Occupation(s)"
        help "choose 0 or more"
      end
    end
  end

  config.model 'Event' do
    list do
      sort_by :type_
      field :recno do
        label "Event id"
      end
      field :type_ do
        sort_reverse false
      end
      field :label
      field :indiv_id do
        label "Subj (if applic)"
      end
      field :period_text do
        label "When"
      end
      field :year
    end

    edit do
      field :recno do
        label "Event id"
        help "Display only; do not enter or alter"
      end
      field :type_ do
        label "Type"
        help "Select from dropdown"
      end
      field :label do
        label "Label, e.g. 'Birth of Horace Debussey Jones'"
      end
      field :period_text do
        label "When"
        help "Descriptive phrase, if applicable; e.g. About Mar 1832"
      end
      field :event_date do
        label "Date"
        help "Certain date if known"
      end
      field :year do
        label "Year (certain)"
        help "Integer"
      end
      field :year_abt do
        label "Year (approx.)"
        help "Integer"
      end
      field :year_est do
        label "Year (machine est.)"
        help "Use Year (approx.) for new records"
      end
      # field :place do
      #   help "address, city, province, country; e.g. 'Russell Square, London, U.K.'"
      # end
      field :place_id do
        label "Place Id"
        help "From Places table"
      end
      field :notes
      field :cause
    end
  end
end
