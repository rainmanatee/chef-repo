# Copyright (c) 2013, Arista Networks
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
#   Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
# 
#   Neither the name of the {organization} nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
class Chef
  class Recipe
    def get_config()
      config_provider = node[:eos][:config][:provider]
      Chef::Log.info "My config provider is #{config_provider}"
     
      if config_provider == "databag"
        databag = node[:eos][:config][:databag]
        Chef::Log.info "My data bag is #{databag}"

        identifier = node[:eos][:config][:identifier]
        Chef::Log.info "Eos config identifer is #{identifier}"

        case identifier
          when "hostname"
            identity = node[:hostname]
          when "macaddress"
            identity = node[:eos][:version][:macaddress]
          when "serialnum"
            identity = node[:eos][:version][:serialnumber]
          when "model"
            identity= node[:eos][:version][:model]
        end
        Chef::Log.info "Eos config identity is #{identity}"

        config = data_bag_item(databag, identity)
        return config
      elsif config_provider == "other"
        return nil
      else
        Chef::Log.fatal "Unknown or unsupported config provider"
      end
    end
  end
end