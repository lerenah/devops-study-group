tetra-tmux-new(){
  local sessionName="${1:-"untitled-session"}
  local scriptName="${2:-"/dev/null"}
  tmux new-session -d -s "$sessionName" "$scriptName"
}

tetra-tmux-list(){
  tmux list-sessions # aka tmux ls
}

# creates session without starting a script
tetra-tmux-join(){
  #tmux attach -t $1     
  tmux attach-session -d -t $1 # -d resizes to screen
  # $? is result of attempt to attach
  #[ $? == 1 ] && tmux new -s $1 
  [ $? == 1 ] && tetra-tmux-new 
}

tetra-tmux-kill(){
  tmux kill-session -t $1
}

tetra-tmux-kill-server(){
  tmux kill-server
}

