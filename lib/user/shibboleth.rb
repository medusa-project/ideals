# frozen_string_literal: true

# This type of user comes from the shibboleth authentication strategy

require_relative "../user"

module User
  class Shibboleth < User::User
    def self.from_omniauth(auth)
      return nil unless auth && auth[:uid]

      user = User::Shibboleth.find_by(provider: auth["provider"], uid: auth["uid"])

      if user
        user.update_with_omniauth(auth)
      else
        user = User::Shibboleth.create_with_omniauth(auth)
      end

      user
    end

    def self.create_with_omniauth(auth)
      create! do |user|
        user.provider = auth["provider"]
        user.uid = auth["uid"]
        user.email = auth["info"]["email"]
        user.username = (auth["info"]["email"]).split("@").first
        user.name = display_name((auth["info"]["email"]).split("@").first)
        user.role = user_role(auth["uid"])
      end
    end

    def update_with_omniauth(auth)
      update!(
        provider: auth["provider"],
        uid:      auth["uid"],
        email:    auth["info"]["email"],
        username: (auth["info"]["email"]).split("@").first,
        name:     User::Shibboleth.display_name((auth["info"]["email"]).split("@").first),
        role:     User::Shibboleth.user_role(auth["uid"])
      )
    end

    def self.user_role(email)
      role = "guest"

      if email.respond_to?(:split)

        netid = email.split("@").first

        if netid.respond_to?(:length) && !netid.empty?

          admins = IDEALS_CONFIG[:admin][:netids].split(", ")

          role = if admins.include?(netid)
                   Ideals::UserRole::ADMIN
                 elsif can_deposit(email)
                   Ideals::UserRole::DEPOSITOR
                 else
                   Ideals::UserRole::GUEST
                 end
        end

      end

      role
    end

    def self.can_deposit(email)
      netid = netid_from_email(email)
      return false unless netid

      response = open("http://quest.grainger.uiuc.edu/directory/ed/person/#{netid}").read
      # Rails.logger.warn response
      # response_nospace = response.gsub(">\r\n", "")
      # response_nospace = response_nospace.gsub("> ", "") while response_nospace.include?("> ")
      # response_noslash = response_nospace.gsub("\"", "'")
      xml_doc = Nokogiri::XML(response)
      xml_doc.remove_namespaces!
      # Rails.logger.warn xml_doc.to_xml
      employee_type = xml_doc.xpath("//attr[@name='uiuceduemployeetype']").text
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
        student_level = xml_doc.xpath("//attr[@name='uiucedustudentlevelcode']").text
        student_level.strip!
        return false if student_level == "1U" # undergraduate

        return true
      when "T"
        # Retiree"
        return true
      when "U"
        # Unpaid"
        primary_affiliation = xml_doc.xpath("//attr[@name='edupersonprimaryaffiliation']").text
        primary_affiliation.strip!
        return primary_affiliation == "staff"
      when "V"
        # Virtual"
        return false
      when "W"
        # One Time Pay"
        return false
      else
        student_level = xml_doc.xpath("//attr[@name='uiucedustudentlevelcode']").text
        return false unless student_level

        student_level.strip!
        return false if student_level == "1U" # undergraduate

        return true
      end
    end

    def self.display_name(email)
      netid = netid_from_email(email)

      return "Unknown" unless netid

      begin
        response = open("http://quest.grainger.uiuc.edu/directory/ed/person/#{netid}").read
        xml_doc = Nokogiri::XML(response)
        xml_doc.remove_namespaces!
        display_name = xml_doc.xpath("//attr[@name='displayname']").text
        display_name.strip!
        display_name
      rescue OpenURI::HTTPError
        "Unknown"
      end
    end

    def self.netid_from_email(email)
      return nil unless email.respond_to?(:split)

      netid = email.split("@").first
      return nil unless netid.respond_to?(:length) && !netid.empty?

      netid
    end
  end
end
