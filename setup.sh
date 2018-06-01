#!/bin/bash
set -e

source ./dotfiles/env.vars

# Add the necessary repos
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Currently the bionic repos do not have a stable version of docker-ce
# As a workaround add the artful repo to install docker
# See: https://github.com/docker/for-linux/issues/290
if [ $(lsb_release -cs) == "bionic" ]; then
  sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu artful stable"
fi

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Install all the required packages
sudo apt-get update
sudo apt-get install zsh \
                    libssl-dev \
                    zlib1g-dev \
                    libbz2-dev \
                    libreadline-dev \
                    libsqlite3-dev \
                    curl \
                    build-essential \
                    gcc \
                    g++ \
                    docker-ce

# Set zsh to be the default shell and enable the prezto config
zsh - <<'EOF'
  git clone --recursive https://github.com/sorin-ionescu/prezto.git   "${ZDOTDIR:-$HOME}/.zprezto"
  setopt EXTENDED_GLOB
  for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
    ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
  done
EOF

chsh -s /bin/zsh

# Create a local bin directory for installing scripts/symlinks
mkdir -p ${B_LOCAL_BIN_DIR}

# Create directory for workspace
if [ ! -d "${B_WORKSPACE_DIR}" ]; then mkdir -p "${B_WORKSPACE_DIR}"; fi

# Install pyenv and plugins and setup default python environment
if [ ! -d "${B_PYTHON_VENV_DIR}" ]; then mkdir -p "${B_PYTHON_VENV_DIR}"; fi

git clone https://github.com/pyenv/pyenv.git ~/.pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
git clone https://github.com/pyenv/pyenv-virtualenvwrapper.git $(pyenv root)/plugins/pyenv-virtualenvwrapper
eval "$(pyenv init -)"

export WORKON_HOME="${B_WORKSPACE_DIR}"
export PROJECT_HOME="${B_PYTHON_VENV_DIR}"

pyenv install "${B_PYTHON3_VERSION}"
pyenv install "${B_PYTHON2_VERSION}"

pyenv virtualenv "${B_PYTHON3_VERSION}" jupyter3
pyenv virtualenv "${B_PYTHON3_VERSION}" tools3
pyenv virtualenv "${B_PYTHON2_VERSION}" ipython2
pyenv virtualenv "${B_PYTHON2_VERSION}" tools2

pyenv activate jupyter3
pip install jupyter
python -m ipykernel install --user
pyenv deactivate

pyenv activate ipython2
pip install ipykernel
python -m ipykernel install --user
pyenv deactivate

pyenv global "${B_PYTHON3_VERSION}" "${B_PYTHON2_VERSION}" jupyter3 ipython2 tools3 tools2

ipython profile create
cp scripts/00-detect-virtualenv-sitepackages.py ~/.ipython/profile_default/startup

# Install and configure golang environment
git clone https://github.com/syndbg/goenv.git ~/.goenv
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"

goenv install "${B_GO_VERSION}"
goenv global "${B_GO_VERSION}"

mkdir -p ${B_WORKSPACE_DIR}/go/pkg
mkdir -p ${B_WORKSPACE_DIR}/go/bin
mkdir -p ${B_WORKSPACE_DIR}/go/src

# Install dep for dependency management
curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
ln -s ${GOPATH}/bin/dep ${B_LOCAL_BIN_DIR}/dep

# Ruby Environment
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
cd ~/.rbenv && src/configure && make -C src
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

mkdir -p "$(rbenv root)"/plugins
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

rbenv install "${B_RUBY_VERSION}"
rbenv global "${B_RUBY_VERSION}"
gem install bundler

# Node Environment
git clone https://github.com/nodenv/nodenv.git ~/.nodenv
cd ~/.nodenv && src/configure && make -C src
export PATH="$HOME/.nodenv/bin:$PATH"
eval "$(nodenv init -)"

mkdir -p "$(nodenv root)"/plugins
git clone https://github.com/nodenv/node-build.git $(nodenv root)/plugins/node-build

nodenv install "${B_NODE_VERSION}"
nodenv global "${B_RUBY_VERSION}"
sudo apt-get install --no-install-recommends yarn

# Link the dotfiles to home directory
ln -sf dotfiles/zshrc ~/.zshrc
ln -sf dotfiles/zpreztorc ~/.zpreztorc
ln -sf dotfiles/env.vars ~/.env.vars