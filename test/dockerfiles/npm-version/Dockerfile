# https://github.com/tonistiigi/binfmt/issues/215#issuecomment-2613934823
FROM node:22-bullseye
RUN <<EOT
  set +ex
  timeout 10m sh -c 'while test $? -eq 0; do npm --version; done'
  exitcode=$?
  if [ $exitcode -eq 0 ] || [ $exitcode -eq 124 ] || [ $exitcode -eq 143 ]; then
    exit 0
  fi
  exit $exitcode
EOT
