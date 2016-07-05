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

  def custom_label_indiv
    "#{self.fullname}"
    "#{self.fullname}"+"_"+"#{self.indiv_id}"
  end

  def custom_label_occu
    "#{self.class_}"
  end
  #
  def custom_label_particip
    "#{self.actor_id}"+"_"+"#{self.role}"
  end

  Event.class_eval do
    def custom_label_event
      "#{self.evlabel}"
    end
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
    object_label_method do
      :custom_label_indiv
    end
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
        help "No titles/suffixes like 'Dr.' or 'OBE'"
      end
      field :sex do
        label "Sex"
        help "M or F"
      end
      field :givn do
        label "Given name(s)"
        help "First, middle"
      end
      field :surn do
        label "Surname"
        help "without prefix (e.g. 'von' or 'de'); add below"
      end
      field :spfx do
        label "surname prefix"
        help "e.g. 'von', 'de'"
      end
      field :marnm do
        label "Married name"
        help ""
      end
      field :npfx do
        label "Name prefix"
        help "e.g. 'Sir', 'Countess', 'Capt.'"
      end
      field :nsfx do
        label "Name suffix"
        help "e.g. '7th Earl of Dunmore', or 'RN, CBE'"
      end
      field :odnb_id do
        label "ODNB id"
        help "ODNB id if applicable"
      end
      field :occus do
        label "Occupation(s)"
        help "choose 0 or more"
      end
      field :notes do
        label "Notes"
      end
    end
  end

  config.model 'Particip' do
    object_label_method do
      :custom_label_particip
    end

    list do
      field :event do
        label "Event (type: id)"
      end
      field :indiv do
        label "Individual"
      end
      field :role do
        label "Role"
      end
    end
    edit do
      field :event do
        label "Event ID"
        help "Enter ID appearing above (w/o the '#'); if none,
          click 'Save and edit' button for Event record"
      end
      field :indiv do
        label "Individual"
        help ""
      end
      field :role do
        label "Role"
        help "BIRT(mother, father, child); DEAT(deceased); MARR(husband, wife); RESI(resident); OCCU(principal)"
      end
    end
  end

  config.model 'Event' do
    # object_label_method do
    #   :custom_label_event
    # end
    list do
      sort_by :recno
      field :recno do
        label "Event id"
        sort_reverse true
      end
      # field :evlabel do
      #   label "evlabel"
      # end
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
      # field :indivs do
      #   label 'Indiv participants'
      # end
      field :type_ do
        label "Type"
        help "Select from dropdown"
      end
      field :indiv_id do
        label "Subject indiv_id"
        help "for all types <em>except</em> MARR"
      end
      field :particips do
        label "Particip(ation) records"
        help "*** First click 'Save and edit' to get Event ID"
      end
      field :label do
        label "Label"
        help "e.g. 'Birth of <fullname>'; Marriage of <fullname> and <fullname>"
      end
      field :period_text do
        label "When"
        help "Textual value given; e.g. '1832', or 'About Mar 1832'"
      end
      field :event_date do
        label "Date certain"
        help "If known; change calendar year, then click to MM/DD"
      end
      field :year do
        label "Year (certain)"
        help "Integer"
      end
      field :year_abt do
        label "Year (approx.)"
        help "If year is uncertain"
      end
      field :year_est do
        label "Year (estimated)"
        help "If year is entirely unknown (incl e.g. death for living INDIV), enter an estimate"
      end
      field :place_text do
        label "Place text"
        help "address, city, province, country; e.g. 'Russell Square, London, U.K.'"
      end
      field :place_id do #, :enum do
        # enum do
        #   Place.all.map {|p| [p.dbname, p.placeid]}
        # end
        label "Mapped place id (integer)"
        help "for UK county (incl. London), US state, or country; From Places table"
      end
      field :notes do
        help "If given"
      end
      field :cause do
        help "If given"
      end
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

  config.model 'Occu' do
    object_label_method do
      :custom_label_occu
    end
    edit do
      field :class_ do
        label "Class"
        help "Lower case"
      end
      field :parent_class do
        label "Parent class"
        help "Top-level 'container'"
      end
      field :is_parent do
        label "Is parent?"
        help "Check if class has/will have 'children'"
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
