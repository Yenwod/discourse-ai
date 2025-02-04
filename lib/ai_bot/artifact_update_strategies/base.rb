# frozen_string_literal: true
module DiscourseAi
  module AiBot
    module ArtifactUpdateStrategies
      class InvalidFormatError < StandardError
      end
      class Base
        attr_reader :post, :user, :artifact, :artifact_version, :instructions, :llm

        def initialize(llm:, post:, user:, artifact:, artifact_version:, instructions:)
          @llm = llm
          @post = post
          @user = user
          @artifact = artifact
          @artifact_version = artifact_version
          @instructions = instructions
        end

        def apply(&progress)
          changes = generate_changes(&progress)
          parsed_changes = parse_changes(changes)
          apply_changes(parsed_changes)
        end

        private

        def generate_changes(&progress)
          response = +""
          llm.generate(build_prompt, user: user) do |partial|
            progress.call(partial) if progress
            response << partial
          end
          response
        end

        def build_prompt
          # To be implemented by subclasses
          raise NotImplementedError
        end

        def parse_changes(response)
          # To be implemented by subclasses
          raise NotImplementedError
        end

        def apply_changes(changes)
          # To be implemented by subclasses
          raise NotImplementedError
        end
      end
    end
  end
end
