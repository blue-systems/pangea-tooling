require_relative '../ci-tooling/lib/logger'

fail 'Need target and changes file!' unless ARGV.count >= 2
fail 'File is not a changes file!' unless ARGV[2].end_with? '.changes'

DPUT_CONTENTS = "[plasma]
fqdn = dci.pangea.pub
login = publisher
method = sftp
incoming = /home/publisher/kde/incoming
run_dinstall = 0
allow_unsigned_uploads = 1

[maui]
fqdn = dci.pangea.pub
login = publisher
method = sftp
incoming = /home/publisher/maui/incoming
run_dinstall = 0
allow_unsigned_uploads = 1
"

$logger = new_logger

def run_cmd(cmd)
    retry_count = 0
    begin
        if retry_count <= 5
            raise unless system(cmd)
        else
            $logger.fatal("Tried to run #{cmd} but retry count exceeded!")
            exit 1
        end
    rescue RuntimeError
        retry_count += 1
        retry
    end
end

DPUT_CF = ENV['HOME'] + '/.dput.cf'
File.open(DPUT_CF, 'w') { |f|
    f.puts(DPUT_CONTENTS)
}

run_cmd("dput #{ARGV[1]} #{ARGV[2]}")

$logger.close
