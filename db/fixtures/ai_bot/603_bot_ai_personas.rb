# frozen_string_literal: true

DiscourseAi::AiBot::Personas::Persona.system_personas.each do |persona_class, id|
  persona = AiPersona.find_by(id: id)
  if !persona
    persona = AiPersona.new
    persona.id = id
    if persona_class == DiscourseAi::AiBot::Personas::WebArtifactCreator
      # this is somewhat sensitive, so we default it to staff
      persona.allowed_group_ids = [Group::AUTO_GROUPS[:staff]]
    else
      persona.allowed_group_ids = [Group::AUTO_GROUPS[:trust_level_0]]
    end
    persona.enabled = true
    persona.priority = true if persona_class == DiscourseAi::AiBot::Personas::General
  end

  names = [
    persona_class.name,
    persona_class.name + " 1",
    persona_class.name + " 2",
    persona_class.name + SecureRandom.hex,
  ]
  persona.name = DB.query_single(<<~SQL, names, id).first
        SELECT guess_name
        FROM (
          SELECT unnest(Array[?]) AS guess_name
          FROM (SELECT 1) as t
        ) x
        LEFT JOIN ai_personas ON ai_personas.name = x.guess_name AND ai_personas.id <> ?
        WHERE ai_personas.id IS NULL
        ORDER BY x.guess_name ASC
        LIMIT 1
      SQL

  persona.description = persona_class.description

  persona.system = true
  instance = persona_class.new
  tools = {}
  instance.tools.map { |tool| tool.to_s.split("::").last }.each { |name| tools[name] = nil }
  existing_tools = persona.tools || []

  existing_tools.each do |tool|
    if tool.is_a?(Array)
      name, value = tool
      tools[name] = value if tools.key?(name)
    end
  end

  persona.tools = tools.map { |name, value| [name, value] }

  persona.system_prompt = instance.system_prompt
  persona.top_p = instance.top_p
  persona.temperature = instance.temperature
  persona.save!(validate: false)
end
