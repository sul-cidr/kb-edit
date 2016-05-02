RailsAdmin.config do |config|
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
      sort_by :recno
      field :recno do
        sort_reverse true
      end
      field :occus do
        label "Occupation(s)"
      end
      # sort_by :surn
      # field :surn do
      #   sort_reverse false
      # end
    end

    edit do
      # exclude_fields :indiv_id, :recno, :reli, :fams, :famc, :sim20, :birt, :deat,
      # :perioddist, :search_names, :perioddist_new, :chantext, :chandate,
      # :diedyoung

      field :fullname do
        label "Full name"
      end
      field :sex do
        label "Sex"
        help "M or F"
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

  config.model 'Particip' do
    list do
    end
    edit do
      field :event do
        label "Event"
      end
      field :indiv do
        label "Individual"
      end
      field :role do
        label "Role"
      end
    end
  end

  config.model 'Event' do
    list do
      sort_by :recno
      field :recno do
        label "Event id"
        sort_reverse true
      end
      field :type_ do
        label "Type"
      end
      field :label do
        label "Event"
      end
      # field :indiv_id do
      #   label "Subj (if applic)"
      # end
      field :period_text do
        label "When"
      end
      field :year
    end

    edit do
      field :indivs do
        label 'event participants'
      end
      field :indiv_id do
        label "Subject indiv_id"
        help "If applicable"
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
      field :place_text do
        label "Place name"
        help "address, city, province, country; e.g. 'Russell Square, London, U.K.'"
      end
      field :place_id do #, :enum do
        # enum do
        #   Place.all.map {|p| [p.dbname, p.placeid]}
        # end
        label "Mapped place id (integer)"
        help "for UK county (incl. London), US state, or country; From Places table"
      end

      field :notes
      field :cause
    end
  end
  config.model 'Place' do
    list do
      field :placeid do
        label "Place id"
      end
      field :dbname do
        label "Place name"
      end
      field :admin1 do
        label "admin1"
      end
      field :admin2 do
        label "admin2"
      end
      field :ccode do
        label "country"
      end
    end
    edit do
      # field :placeid do
      #   label "Place id"
      # end
      field :dbname do
        label "Place name"
      end
      field :admin1 do
        label "admin1"
        help "UK country (England, Scotland, Wales) if applicable"
      end
      field :admin2 do
        label "admin2"
        help "UK county (incl. London) or US state, if applicable"
      end
      field :ccode do
        label "country code"
        help "2 characters"
      end
    end
  end
end
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
