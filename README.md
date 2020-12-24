## sumo

### Setup oh-my-zsh

#### Pre-requisite - Install json-query 
```zsh
pushd $ZSH/custom/plugins && \
  git clone git@github.com:johnlayton/torbaystreet.git json-query && \
  popd || echo "I'm broken"
```
```zsh
plugins=(... json-query)
```

#### Install buildkite plugin
```zsh
pushd $ZSH/custom/plugins && \
  git clone git@github.com:johnlayton/mccollstreet.git buildkite && \
  popd || echo "I'm broken"
```
```zsh
plugins=(... buildkite)
```

### Setup other

```zsh
pushd $HOME && \
  git clone git@github.com:johnlayton/mccollstreet.git .buildkite && \
  popd || echo "I'm broken"
```

```zsh
source ~/.buildkite/buildkite.plugin.zsh
```


### Usage

#### 
```zsh
```

#### 
```zsh
```

#### 
```zsh
```
