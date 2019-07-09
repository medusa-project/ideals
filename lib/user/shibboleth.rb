# This type of user comes from the shibboleth authentication strategy

require_relative '../user'

class User::Shibboleth < User::User

  def self.from_omniauth(auth)
    if auth && auth[:uid]
      user = User::Shibboleth.find_by_provider_and_uid(auth["provider"], auth["uid"])

      if user
        user.update_with_omniauth(auth)
      else
        user = User::Shibboleth.create_with_omniauth(auth)
      end

      return user

    else
      return nil
    end
  end

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.email = auth["info"]["email"]
      user.username = (auth["info"]["email"]).split('@').first
      user.name = User::Shibboleth.display_name((auth["info"]["email"]).split('@').first)
      user.role = user_role(auth["uid"])
    end
  end

  def update_with_omniauth(auth)
    update_attribute(:provider, auth["provider"])
    update_attribute(:uid, auth["uid"])
    update_attribute(:email, auth["info"]["email"])
    update_attribute(:username, self.email.split('@').first)
    update_attribute(:name, User::Shibboleth.display_name(self.username))
    update_attribute(:role, User::Shibboleth.user_role(auth["uid"]))
    self
  end

  def self.user_role(email)

    role = "guest"

    if email.respond_to?(:split)

      netid = email.split('@').first

      if netid.respond_to?(:length) && netid.length > 0

        admins = IDEALS_CONFIG[:admin][:netids].split(", ")

        if admins.include?(netid)
          role = Ideals::UserRole::ADMIN
        elsif can_deposit(email)
          role = Ideals::UserRole::DEPOSITOR
        else
          role = Ideals::UserRole::GUEST
        end
      end

    end

    role

  end

  def self.can_deposit(email)
    netid = netid_from_email(email)
    if netid

      # exception for Patrick Brown, former faculty who still has some datasets to deposit.
      if netid == 'pjb34'
        return true
      end

      # exception for Neil Smalheiser, UIC faculty who is also Affiliated Faculty with the iSchool at Illinois
      if netid == 'neils'
        return true
      end

      # exception for Thien Le, student assistant for a dataset
      if netid == 'thienle2'
        return true
      end

      response = open("http://quest.grainger.uiuc.edu/directory/ed/person/#{netid}").read
      # Rails.logger.warn response
      # response_nospace = response.gsub(">\r\n", "")
      #response_nospace = response_nospace.gsub("> ", "") while response_nospace.include?("> ")
      #response_noslash = response_nospace.gsub("\"", "'")
      xml_doc = Nokogiri::XML(response)
      xml_doc.remove_namespaces!
      # Rails.logger.warn xml_doc.to_xml
      employee_type = xml_doc.xpath("//attr[@name='uiuceduemployeetype']").text()
      employee_type.strip!
      # Rails.logger.warn "netid then employee type:"
      # Rails.logger.warn netid
      # Rails.logger.warn employee_type
      case employee_type
      when "A"
        # Faculty
        return true
      when "B"
        # Acad. Prof."
        return true
      when "C", "D"
        # Civil Service"
        return true
      when "E"
        # Extra Help"
        return false
      when "G"
        # Grad. Assisant"
        return true
      when "H"
        # Acad./Grad. Hourly"
        return true
      when "L"
        # Lump Sum"
        return false
      when "M"
        # Summer Help"
        return false
      when "P"
        # Post Doc."
        return true
      when "R"
        # Medical Resident"
        return true
      when "S"
        # Student"
        student_level = xml_doc.xpath("//attr[@name='uiucedustudentlevelcode']").text()
        student_level.strip!
        if student_level == "1U"
          # undergraduate
          return false
        else
          return true
        end
      when "T"
        # Retiree"
        return true
      when "U"
        # Unpaid"
        primary_affiliation = xml_doc.xpath("//attr[@name='edupersonprimaryaffiliation']").text()
        primary_affiliation.strip!
        return primary_affiliation == "staff"
      when "V"
        # Virtual"
        return false
      when "W"
        # One Time Pay"
        return false
      else
        student_level = xml_doc.xpath("//attr[@name='uiucedustudentlevelcode']").text()
        return false unless student_level
        student_level.strip!
        if student_level == "1U"
          # undergraduate
          return false
        else
          return true
        end
      end
    else
      return false
    end
  end

  def self.display_name(email)

    netid = netid_from_email(email)

    return "Unknown" unless netid

    # exception for Neil Smalheiser, UIC faculty who is also Affiliated Faculty with the iSchool at Illinois
    if netid == 'neils'
      "Neil Smalheiser"
    else

      begin

        response = open("http://quest.grainger.uiuc.edu/directory/ed/person/#{netid}").read
        xml_doc = Nokogiri::XML(response)
        xml_doc.remove_namespaces!
        display_name = xml_doc.xpath("//attr[@name='displayname']").text()
        display_name.strip!

        display_name

      rescue OpenURI::HTTPError

        "Unknown"

      end

    end

  end

  def self.netid_from_email(email)
    if email.respond_to?(:split)
      netid = email.split('@').first
      if netid.respond_to?(:length) && netid.length > 0
        return netid
      else
        return nil
      end
    else
      return nil
    end
  end

end

