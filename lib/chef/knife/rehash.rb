#
# Author:: Steven Danna <steve@chef.io>
# Copyright:: Copyright 2015-2016, Chef Software, Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative ""
require_relative "core/subcommand_loader"

class Chef
  class Knife
    class Rehash < Chef::Knife
      banner "knife rehash"

      def run
        if ! Chef::Knife::SubcommandLoader.autogenerated_manifest?
          ui.msg "Using knife-rehash will speed up knife's load time by caching the location of subcommands on disk."
          ui.msg "However, you will need to update the cache by running `knife rehash` anytime you install a new knife plugin."
        else
          reload_plugins
        end
        write_hash(generate_hash)
      end

      def reload_plugins
        # The subcommand_loader for this knife command should _always_ be the GemGlobLoader.  The GemGlobLoader loads
        # plugins from disc and ensures the hash we write is always correct.  By this point it should also already have
        # loaded plugins and `load_commands` shouldn't have an effect.
        Chef::Knife.subcommand_loader.load_commands
      end

      def generate_hash
        output = if Chef::Knife::SubcommandLoader.plugin_manifest?
                   Chef::Knife::SubcommandLoader.plugin_manifest
                 else
                   { Chef::Knife::SubcommandLoader::HashedCommandLoader::KEY => {} }
                 end
        output[Chef::Knife::SubcommandLoader::HashedCommandLoader::KEY]["plugins_paths"] = Chef::Knife.subcommand_files
        output[Chef::Knife::SubcommandLoader::HashedCommandLoader::KEY]["plugins_by_category"] = Chef::Knife.subcommands_by_category
        output
      end

      def write_hash(data)
        plugin_manifest_dir = File.expand_path("..", Chef::Knife::SubcommandLoader.plugin_manifest_path)
        FileUtils.mkdir_p(plugin_manifest_dir) unless File.directory?(plugin_manifest_dir)
        File.open(Chef::Knife::SubcommandLoader.plugin_manifest_path, "w") do |f|
          f.write(Chef::JSONCompat.to_json_pretty(data))
          ui.msg "Knife subcommands are cached in #{Chef::Knife::SubcommandLoader.plugin_manifest_path}. Delete this file to disable the caching."
        end
      end
    end
  end
end
