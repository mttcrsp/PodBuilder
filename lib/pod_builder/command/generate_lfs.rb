require 'pod_builder/core'

module PodBuilder
  module Command
    class GenerateLFS
      def self.call(options)
        Configuration.check_inited

        unless Configuration.lfs_update_gitattributes
           return false
        end

        gitattributes_excludes = ["*.h", "*.hh", "*.m", "*.mm", "*.i", "*.c", "*.cc", "*.cxx", "*.cpp", "*.def", "*.inc", "*.inl", "*.swift", "*.modulemap", "*.strings", "*.png", "*.jpg", "*.gif", "*.html", "*.htm", "*.js", "*.json", "*.xml", "*.txt", "*.md", "*.rb", "*.sh", "*.py", "*.plist", ".*"]

        gitattributes_includes_frameworks = ["**/* filter=lfs diff=lfs merge=lfs !text"]
        write_attributes(PodBuilder::basepath("Rome"), gitattributes_includes_frameworks, gitattributes_excludes)
        write_attributes(PodBuilder::basepath("dSYM"), gitattributes_includes_frameworks, gitattributes_excludes)

        if Configuration.lfs_include_pods_folder
          gitattributes_includes_pods = ["**/*.frameworks/**/* filter=lfs diff=lfs merge=lfs !text"]
          write_attributes(PodBuilder::project_path("Pods"), gitattributes_includes_pods, gitattributes_excludes)
        end
      end

      private

      def self.filter_files_by_size(files, size_kb)
        return files.select { |x| File.size(x) / 1024 > Configuration.lfs_min_file_size }
      end

      def self.write_attributes(path, gitattributes_includes, gitattributes_excludes)
        stop_marker = "# pb<stop>"
        start_marker = "# pb<start> (lines up to `#{stop_marker}` are autogenerated, don't modify this section)"

        gitattributes_items = [start_marker]
        gitattributes_items += gitattributes_includes + gitattributes_excludes.map { |x| "#{x} !filter !merge !diff" }
        gitattributes_items += [stop_marker]

        gitattributes_path = File.join(gitattributes_path, ".gitattributes")

        if !File.exist?(gitattributes_path)
          FileUtils.touch(gitattributes_path)
        end
        
        gitattributes_content = File.read(gitattributes_path)

        podbuilder_start_line_found = false
        gitattributes_content.each_line do |line|
          stripped_line = line.strip
          if stripped_line.start_with?(stop_marker)
            podbuilder_start_line_found = false
            next
          elsif stripped_line.start_with?(start_marker)
            podbuilder_start_line_found = true
          end

          unless !podbuilder_start_line_found
            next
          end

          gitattributes_items.push(line.strip)
        end
        
        File.write(gitattributes_path, gitattributes_items.join("\n"))
      end
    end
  end
end       