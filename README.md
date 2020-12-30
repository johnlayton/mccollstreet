## buildkite

### Setup oh-my-zsh

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
