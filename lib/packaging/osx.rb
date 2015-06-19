module Pkg::OSX
  class << self
    def sign_osx
      signing_keychain    = Pkg::Config.signing_keychain
      signing_keychain_pw = Pkg::Config.signing_keychain_pw
      signing_cert        = Pkg::Config.signing_cert
      signing_server      = Pkg::Config.signing_server
      signing_ssh_key     = Pkg::Config.signing_ssh_key

      ssh_host_string = "-i #{signing_ssh_key} #{ENV['USER']}@#{signing_server}"
      rsync_host_string = "-e 'ssh -i #{signing_ssh_key}' #{ENV['USER']}@#{signing_server}"

      work_dir  = "/tmp/#{random_string(8)}"
      mount     = File.join(work_dir, "mount")
      signed    = File.join(work_dir, "signed")
      output    = File.join("pkg", "apple", "#{Pkg::Config.yum_repo_name}")
      Pkg::Util::Net.remote_ssh_cmd(ssh_host_string, "mkdir -p #{work_dir}/{mount,signed}")
      dmgs = Dir.glob("pkg/apple/**/*.dmg")
      Pkg::Util::Net.rsync_to(dmgs.join(" "), rsync_host_string, work_dir)
      Pkg::Util::Net.remote_ssh_cmd(ssh_host_string, %Q[for dmg in #{dmgs.map { |d| File.basename(d, ".dmg") }.join(" ")}; do
        /usr/bin/hdiutil attach #{work_dir}/$dmg.dmg -mountpoint #{mount} -nobrowse -quiet ;
        /usr/bin/security -v unlock-keychain -p "$SIGNING_KEYCHAIN_PW" "$SIGNING_KEYCHAIN" ;
          for pkg in $(ls #{mount}/*.pkg | xargs -n 1 basename); do
            /usr/bin/productsign --keychain "$SIGNING_KEYCHAIN" --sign "$SIGNING_CERT" #{mount}/$pkg #{signed}/$pkg ;
          done
        /usr/bin/hdiutil detach #{mount} -quiet ;
        /bin/rm #{work_dir}/$dmg.dmg ;
        /usr/bin/hdiutil create -volname $dmg -srcfolder #{signed}/ #{work_dir}/$dmg.dmg ;
        /bin/rm #{signed}/* ; done])
      Pkg::Util::Net.rsync_from("#{work_dir}/*.dmg", rsync_host_string, "#{output}")
      Pkg::Util::Net.remote_ssh_cmd(ssh_host_string, "if [ -d '#{work_dir}' ]; then rm -rf '#{work_dir}'; fi")
    end
  end
end
