#!/usr/bin/env bash

# This is a bash script to enable interacting with LLMs via the command line.

#===============================================================================

## Modes
### Default mode
# Default mode uses the default prompt and model for AquaAI. It's nothing
# special.
### Bash mode
# This mode will help with writing bash scripts.
### CLI mode
# CLI mode prompts the AI with system information and will return terminal
# commands. If you wish to run the command simply type run and it will end the
# chat and run the command. You are responsible for validating what the command
# does before running.
### Code Review mode
# This will ask you what changes to look at and will provide a code review of
# the changes. This mode only works if you are currently in a git repo. It can
# look at the past few commits as well as changes that have yet to be committed.
### Reasoning mode
# This uses the best available reasoning model with the default prompt.
# Reasoning models take a task and break them up to subtask to pass to
# specialized models. They are very yappy and take a while to run. Can be good
# for complex tasks.
### Regex mode
# This mode will respond only with regex.
### Git mode
# This mode will respond only with git commands. If you wish to run the command
# simply type run and it will end the chat and run the command. You are
# responsible for validating what the command does before running.

## Special Input
### Edit
# You can type `edit` or `e` as a response and it will open your editor set with
# the EDITOR variable in your shell session. You can then type your query and
# save and exit. From there the program will send your query to the AI.
### Exit
# You can type `exit` or `q` to end the chat. Personally, I never do this just
# use C-c.
### Run
# If you are in cli mode you can type `run` or `r` and the script will run the
# given commands on your system. You are playing with fire with this, but fire
# is useful and fun just be careful.
### Save
# You can type `save` or `s` as a response and the chat history will be saved
# for use at another time. This will also end the chat. Chats are stored in
# `~/.local/share/aquaai`

## Adding custom modes
# There are two variables that need to be set to create a custom mode.
### $selected_model will set the model to be used for the chat.
### $system_prompt will be the prompt that controls how the AI behaves.
# introduce more noise into text generation leading to more out there responses.
#
# Defaults are set for all these but to define a custom mode you should override
# at least one of these in a function. Add a custom flag in the switch statement
# at the bottom of this file and call the function there. See `--bash` as an
# example of how to do this. From there add some documentation to the
# print_help() function and then here.

#===============================================================================

# User configurable variables.
#
# The following are settings that can be overwritten by environment variables.
# You can set these in your .bashrc to have them set each time you open a new
# shell. This script is designed not to be modified so updates can be applied by
# replacing the file with the newest version.
#
#
# Set the url of the ollama server.
#
# export AQUAAI_OLLAMA_URL='192.168.1.156:11434'
#
ollama_url=${AQUAAI_OLLAMA_URL:='https://ai.aquamorph.com'}
#
# Set the default model.
#
# export AQUAAI_DEFAULT_MODEL='qwen2.5-7b-instruct'
#
default_model=${AQUAAI_DEFAULT_MODEL:='qwen2.5:32b-instruct'}
#
# Set the default coding model.
#
# export AQUAAI_CODING_MODEL='qwen2.5-7b-coder'
#
coding_model=${AQUAAI_CODING_MODEL:='qwen2.5-32b-coder'}
#
# In multiline mode, users can input multiple lines of text by pressing the
# Enter key. The message will be sent when the user presses C-d on the keyboard.
#
# export AQUAAI_MULTILINE_MODE=true
#
multiline_mode=${AQUAAI_MULTILINE_MODE:=false}
#
# Enable rich formatting for text output. A formatting program is required for
# this see below.
#
# export AQUAAI_RICH_FORMAT_MODE=true
#
rich_format_mode=${AQUAAI_RICH_FORMAT_MODE:=false}
#
# Path to the program used for rich formatting. I am currently using streamdown
# but you are free to use something different as long as it supports streaming
# text and markdown. Go to the GitHub repo to learn to install streamdown and
# configure: https://github.com/day50-dev/Streamdown
#
# export AQUAAI_RICH_FORMAT_PATH=~/.venv/bin/streamdown
#
rich_format_path=${AQUAAI_RICH_FORMAT_PATH:=streamdown}
#
# Ignore certificate checks.
#
# export AQUAAI_INSECURE_MODE=true
#
insecure_mode=${AQUAAI_INSECURE_MODE:=false}
#
# Use OpenAI api design instead of Ollama.
#
# export AQUAAI_OPENAI_API:=true
#
openai_api=${AQUAAI_OPENAI_API:=true}
#
# Set key used to authenticate with the API.
#
# export AQUAAI_KEY:=true
#
key=${AQUAAI_KEY:=''}
#===============================================================================

# Constants.
OLLAMA_URL=${ollama_url}
CURL_FLAGS=('-sN')
USER=$(whoami)
DATA_DIR="${HOME}/.local/share/aquaai"
RESPONSE_FIFO="${DATA_DIR}/.response"
AGENT_NAME='AquaAI'

# Colors.
CLEAR='\033[0m'
BLUE='\033[0;34m'
RED='\e[1;31m'
LIGHT_GRAY='\e[38;5;247m'

# Globals.
message_history="[]"
cli_mode=false
git_mode=false
code_review_start=false
selected_model=${default_model}

# Error Codes.
ERROR_NO_SAVEFILE=1
ERROR_INVALID_TEMP=2
ERROR_UNKNOWN_OPTION=3
ERROR_UNKNOWN_MODEL=4
ERROR_NO_GIT_REPO=5
ERROR_INVALID_INPUT=6
ERROR_NO_AUTOSAVE=7
ERROR_INVALID_SSL=8
ERROR_UNKNOWN_SSL=9

#===============================================================================

# Give the AI a name. It improves prompting to call it by name.
function name_agent() {
  system_prompt="You are an AI assistant named ${AGENT_NAME}."
}

# Make the AI write and behave better.
function set_better_conversions() {
  system_prompt+=' Be as concise as possible.'
  system_prompt+=' Be extremely accurate.'
  system_prompt+=' Recommend things I would not realize I would benefit from.'
  system_prompt+=' Call out my misconceptions and tell me when I am wrong.'
  system_prompt+=" For personal matters ${AGENT_NAME} is encouraging"
  system_prompt+=' but brutally honest.'
  system_prompt+=' Never sycophantic.'
}

# Set the formatting for all reponses.
function set_response_format() {
  system_prompt+=' Do not wrap response in quotation marks or apostrophes.'
  system_prompt+=' Do not use html to format response.'
}

# Limit format of output to just commands.
function format_for_cli() {
  system_prompt+=" ${AGENT_NAME} does not put commands in quotation marks."
  system_prompt+=" ${AGENT_NAME} does not put commands in markdown."
  system_prompt+=" ${AGENT_NAME} only outputs terminal commands."
}

# Default prompt.
function set_default_agent() {
  name_agent
  system_prompt+=" ${AGENT_NAME} follows the users instructions carefully."
  system_prompt+=" ${AGENT_NAME} responds using extended markdown."
  set_better_conversions
  set_response_format
}

# Set chat to help with command line questions.
function set_cli_agent() {
  local os_version=$(cat /etc/os-release | grep 'PRETTY_NAME' | \
                       sed 's/PRETTY_NAME=//g' | tr -d '"')
  name_agent
  system_prompt+=" ${AGENT_NAME} assists users with ${os_version}."
  format_for_cli
  set_response_format
}

# Set chat to help with bash questions.
function set_bash_agent() {
  name_agent
  system_prompt+=" ${AGENT_NAME} assists users with POSIXs bash."
  system_prompt+=' Format output for view in a command line.'
  system_prompt+=' Do not put commands in quotation marks.'
  system_prompt+=' Use double spaces and the function keyword.'
  system_prompt+=' Write documentation before the function declaration.'
  set_response_format
}

# Set ai to help with code reviews.
function set_code_review_agent() {
  name_agent
  system_prompt+=" ${AGENT_NAME} is a senior software engineer performing a"
  system_prompt+=' code review for a colleague.'
  system_prompt+=''
  set_better_conversions
  system_prompt+=' Show code snipets when helpful.'
  system_prompt+="${AGENT_NAME}'s reports should have the following format:"
  system_prompt+='# Typos'
  system_prompt+='List of all typos you find.'
  system_prompt+='# Formatting and Readability Issues'
  system_prompt+='List of all formatting and readability issues you find.'
  system_prompt+='# Security Issues'
  system_prompt+='List of all security issues you find.'
  system_prompt+='# Other'
  system_prompt+='List of all other issues you find.'
  set_response_format
}

# Set chat to help with git.
function set_git_agent() {
  name_agent
  system_prompt+=" ${AGENT_NAME} assists users with git."
  format_for_cli

  if is_git_repo; then
    system_prompt+="\n\nHere is some information about the current git repo.\n"
    local current_branch=$(git branch --show-current)
    system_prompt+="Current branch: ${current_branch} \n"
    local git_remotes=$(git remote -v)
    system_prompt+="Remotes: ${git_remotes}\n"
  fi
}

# Set chat to help with regex.
function set_regex_agent() {
  name_agent
  system_prompt+=" ${AGENT_NAME} assists users with regex."
  system_prompt+=' Only output a single regex expression.'
  system_prompt+=' Use BRE and ERE regex.'
  format_for_cli
}

# Set chat to help with Home Assistant.
function set_home_assistant_agent() {
  name_agent
  system_prompt+=" ${AGENT_NAME} assists users with Home Assistant programming."
  system_prompt+=" Templating is done with Jinja2."
}

#===============================================================================

# Get the first available model from a given list.
function get_model_from_list() {
  local models=("$@")
  for m in "${models[@]}"; do
    check_if_model_exists $m true
    if [ $? -eq 0 ]; then
      echo "${m}"
      return
    fi
  done
  print_error "could not find any models on the list."
  exit $ERROR_UNKNOWN_MODEL
}

function load_model_from_list() {
  local models=("$@")
  selected_model=$(get_model_from_list "${models[@]}")
  if [[ $? -ne 0 ]]; then
     print_error "could not find any models on the list."
     exit $ERROR_UNKNOWN_MODEL
  fi
}

# Set the default coding model.
function set_coding_model() {
  local models=(${coding_model}
                'qwen2.5-32b-coder'
                'qwen2.5-7b-coder'
                'llama3.3-70b-instruct'
                'hf.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF:Q4_K_M'
                'hf.co/bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF:Q4_K_M'
                'qwen2.5-coder:3b'
                'qwen2.5-coder:0.5b'
               )
  load_model_from_list "${models[@]}"
}

# Set the default reasoning model.
function set_reasoning_model() {
  local models=(${reasing_model}
                'qwen3-32b'
                'gpt-oss-120b'
               )
  load_model_from_list "${models[@]}"
}

#===============================================================================

# Print out help menu.
function print_help() {
  echo 'Interact with the AquaAI via the command line.'
  echo ''
  echo '--delete         - delete a chat from history'
  echo '-l --list        - list available models'
  echo '--load           - load a chat from history'
  echo '--restore        - load last auto saved chat'
  echo ''
  echo '--bash           - help with bash'
  echo '--cli            - help with command line'
  echo '--code-review    - code review of a git project'
  echo '-r --reason      - help with a reasoning model'
  echo '--regex          - help with regex'
  echo '--git            - help with git'
}

# Print out error message.
function print_error() {
  local msg=${1}
  printf "${RED}ERROR: ${msg}\n${CLEAR}"
}

# Check if a given program is installed on the system.
function check_program() {
  if ! command -v ${1} 2>&1 >/dev/null; then
    print_error "${1} not found. Please install ${1}."
    exit ${ERROR_DEPENDENCY}
  fi
}

# Check system for required programs.
function check_requirements() {
  check_program curl
  check_program jq
  check_program fzf
  if [ "${rich_format_mode}" == true ]; then
    check_program ${rich_format_path}
  fi
}

# Get available models info.
function get_models() {
  local model_path=''
  if [ "${openai_api}" == true ]; then
    model_path='/api/models'
  else
    model_path='/api/tags'
  fi
  curl "${CURL_FLAGS[@]}" "${OLLAMA_URL}${model_path}"
}

# Get a list of available models.
function get_models_list() {
  local jq_filter=''
  if [ "${openai_api}" == true ]; then
    jq_filter='.data[].id'
  else
    jq_filter='.models[].model'
  fi
  get_models | jq -r ${jq_filter}
}

# Print list of models.
function print_models() {
  get_models_list | column -t -s $'\t'
}

# Print message variable.
function print_message_history() {
  echo ${message_history}
}

# Print message variable.
function print_debug() {
  echo "Model: ${selected_model}"
  echo 'System Prompt:'
  print_system_prompt
  echo 'Chat History:'
  print_message_history | jq
}

# Print the system prompt.
function print_system_prompt() {
  echo -e "${system_prompt}"
}

# Check if the model exists.
function check_if_model_exists() {
  local model=${1}
  local enable_rc=${2}
  local model_list=($(get_models_list))

  for m in "${model_list[@]}"; do
    if [[ "$m" == "$model" ]]; then
      return 0
    fi
  done

  if [ ${enable_rc} ]; then
     return 1
  else
    print_error "model ${model} does not exists."
    exit $ERROR_UNKNOWN_MODEL
  fi
}

# Convert string to a safe format for later use.
function convert_to_safe_text() {
  echo "${1}" | jq -sR @json
}

# Set the text output color for user input.
function set_user_color() {
  printf "${LIGHT_GRAY}"
}

# Set the text output color for ai response.
function set_ai_color() {
  printf "${CLEAR}"
}

# Set text color to defaults.
function set_clear_color() {
  printf "${CLEAR}"
}

# Print the header for the ai message
function print_ai_start_message() {
  echo -e "\U1F916 AquaAI"
}

# Print the header for the ai message
function print_user_start_message() {
  echo -e "\U1F464 ${USER}"
}

# Opens the user's preferred text editor to allow them to input text.
function editor_input() {
  local editor=${EDITOR:=nano}
  local temp_file=$(mktemp)

  ${editor} ${temp_file}
  local user_input=$(<"$temp_file")
  rm "$temp_file"

  msg=${user_input}
}

# Check if current directory is managed by git.
function is_git_repo() {
  git rev-parse --is-inside-work-tree &> /dev/null
}

# Check if current directory is managed by git.
function check_git_directory() {
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    print_error 'The current directory is not inside a git repository.'
    exit ${ERROR_NO_GIT_REPO}
  fi
}

# Asks the user if they want to include staged git change data.
function gather_staged_changes() {
  echo -n 'Do you want to include staged changes? (y/n)? '
  read response

  if [[ "$response" == 'y' || "$response" == 'yes' ]]; then
    msg+=$(git diff --cached --patch)
  fi
}

# Ask the user if they want to include changes that have not been committed.
function gather_uncommitted_changes() {
  echo -n 'Do you want to include the changes'
  echo -n ' you have yet to commit or stash (y/n)? '
  read response

  if [[ "$response" == 'y' || "$response" == 'yes' ]]; then
    changes=$(git diff)
    msg+=${changes}
  fi
}

# Ask the user for number of commit changes to include in code review.
# Returns a list of changes for the given number of commits.
function gather_commit_changes() {
  echo -n 'How many previous commits do you want to include? '
  local count
  read count

  # Allow hitting enter as a no response.
  if [ -z "$count" ]; then
    return
  fi

  # Validate that the input is a positive integer.
  if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 0 ]; then
    print_error 'Please enter a positive integer for the number of commits.'
    exit ${ERROR_INVALID_INPUT}
  fi

  hashes=$(git log --format=%H -n ${count})
  for h in ${hashes}; do
    commit_message=$(git show ${h})
    msg+="${commit_message}"$'\n'
  done
}

# Create fifo for chat responses.
function create_response_fifo() {
  create_data_dir
  if [ ! -p ${RESPONSE_FIFO} ]; then
    mkfifo ${RESPONSE_FIFO}
  fi
}

# Delete fifo for chat responses.
function remove_response_fifo() {
  if [ -p ${RESPONSE_FIFO} ]; then
    rm ${RESPONSE_FIFO}
  fi
}

# Create response trap to allow user to stop AquaAI.
function create_response_trap() {
  trap 'echo "AquaAI has been interrupted...";' SIGINT
}

# Remove response trap to allow user to exit program.
function remove_response_trap() {
  trap - SIGINT
}

# Get the first message from a saved chat.
function get_first_chat() {
  local file_path=${1}
  source <(cat ${file_path} | grep message_history)
  message_history=$(echo $message_history | \
                      jq -r '[.[] | select(.role == "user")][0].content' \
                      2>/dev/null | sed 's/^"//')
  echo -e $message_history | sed 's/"$//' | tr -d '\n' | cut -c 1-80 \
    | sed ':a;N;$!ba;s/\n//g'
}

# Get an array of all saved chat files.
function get_save_files() {
  save_files=()
  create_data_dir

  for f in $(find "$DATA_DIR" -type f -name "*.chat"); do
    save_files+=("${f}")
  done
}

# Create the data directory if it does not exist.
function create_data_dir() {
  if [ ! -d "$DATA_DIR" ]; then
    mkdir -p "$DATA_DIR"
  fi
}

# Save the current chat to a file.
function save_chat() {
  create_data_dir
  local filename=${1}

 if [ -z "$filename" ]; then
    print_error 'No filename provided.'
    exit ${ERROR_NO_SAVEFILE}
  fi

  declare -p selected_model system_prompt \
          message_history cli_mode > "${DATA_DIR}/${filename}"
}

# Save the current chat to autosave.
function autosave() {
  save_chat 'autosave.chat'
  echo 'Chat has been auto saved'
}

# Find all .chat files in DATA_DIR and use fzf to select one.
function select_chat_file() {
  selected_file=$(select_chat_with_fzf)

  if [ -z "$selected_file" ]; then
    echo 'No file selected.'
    exit ${ERROR_NO_SAVEFILE}
  fi
}

# Delete .chat files in DATA_DIR.
function delete_chat_file() {
  selected_file=$(select_chat_with_fzf)

  if [ -z "$selected_file" ]; then
    echo 'No file selected.'
    exit ${ERROR_NO_SAVEFILE}
  else
    local pretty_name=$(get_first_chat ${selected_file})
    echo -n "do you want to delete '${pretty_name}' (y/n)? "
    read response
    if [[ "$response" == 'y' || "$response" == 'yes' ]]; then
      rm -- "${selected_file}"
      echo "Deleted '${pretty_name}'"
    fi
  fi
}

# Select saved chat with fzf program.
function select_chat_with_fzf() {
  get_friendly_save_names

  local selected_index=$(printf "%s\n" "${friendly_save_files[@]}" \
                           | cat -n | fzf --with-nth 2.. \
                           | awk '{print $1}')
  selected_index=$((${selected_index}-1))

  if [[ -n $selected_index ]]; then
    echo "${save_files[selected_index]}"
  fi
}

# Get an array of the first message in saved chats.
function get_friendly_save_names() {
  get_save_files
  friendly_save_files=()
  for f in "${save_files[@]}"; do
    friendly_save_files+=("$(get_first_chat ${f})")
  done
}

# Validate site certificate.
function check_cert() {
  curl "${CURL_FLAGS[@]}" ${OLLAMA_URL}  2>&1 >/dev/null
  local ec=$?
  if [ "${ec}" == '60' ]; then
    print_error 'unable to get local issuer certificate.'
    echo 'Install the certificate on the system.'
    exit ${ERROR_INVALID_SSL}
  elif [ "${ec}" != '0' ]; then
    print_error 'unknown ssl error.'
    exit ${ERROR_UNKNOWN_SSL}
  fi
}

# Update chat history
function update_history() {
  local role="$1"
  local content="$2"
  message_history=$(echo "$message_history" \
                     | jq --arg role "$role" --arg content \
                     "$content" '. + [{"role": $role, "content": $content}]')
}

# Read input from the user.
function read_user_input() {
  if [ "${multiline_mode}" == true ]; then
    msg=$(awk '{if ($0 == "END") exit; else print}')
  elif [ "${code_review_start}" == true ]; then
    check_git_directory
    msg=''
    gather_uncommitted_changes
    gather_staged_changes
    gather_commit_changes
    code_review_start=false
  else
    read msg
  fi
}

# Handle input related to CLI mode.
function handle_cli_mode() {
  # Check for cli mode
  if [ ${cli_mode} == true ]; then
    if [[ -z $msg || $msg == 'run' || $msg == 'r' ]]; then
      set_clear_color
      autosave
      echo
      local commands=()
      # Get a list of commands
      while IFS= read -r line; do
        commands+=("${line}")
      done <<< "$last_cmd"
      for c in "${commands[@]}"; do
        # Using eval to handle commands that include pipes.
        if [[ "${c}" == *'|'* ]]; then
          eval "${c}"
        else
          ${c}
        fi
      done
      exit 0
    fi
  fi
}

# Check for editor request.
function handle_edit() {
  if [[ $msg == 'edit' || $msg == 'e' ]]; then
    editor_input
    set_user_color
    echo "${msg}"
  fi
}

# Check for debug command.
function handle_debug() {
  if [[ $msg == 'debug' ]]; then
    print_debug
    return 1
  fi
  return 0
}

# Check for save command.
function handle_save() {
  if [[ $msg == 'save' || $msg == 's' ]]; then
    echo "Saving chat history"
    save_chat "$(date +%Y%m%d%H%M%S).chat"
    exit 0
  fi
}

# Chat converstation loop.
function chat_loop() {
  check_if_model_exists ${selected_model}
  update_history 'system' "$system_prompt"
  while true; do
    chat
  done
}

# Main chat loop.
function chat() {
  # Get user input.
  set_user_color
  print_user_start_message
  read_user_input
  echo

  # Handle user input.
  local rc=0
  handle_edit
  handle_cli_mode
  handle_debug
  rc=$((rc + $?))
  handle_save
  rc=$((rc + $?))
  if [ "$rc" -ne 0 ]; then
    return
  fi
  update_history 'user' "${msg}"

  # Prepare JSON payload.
  JSON_PAYLOAD=$(jq -n \
    --arg model "$selected_model" \
    --argjson messages "$message_history" \
      '{model: $model,  messages: $messages, stream: true}')

  set_ai_color
  print_ai_start_message

  create_response_fifo
  create_response_trap
  # Render to console.
  if [ "${rich_format_mode}" == true ]; then
    cat ${RESPONSE_FIFO} | ${rich_format_path} &
  else
    cat ${RESPONSE_FIFO} &
  fi
  local flags=("${CURL_FLAGS[@]}")
  local chat_path=''
  local filter=''
  if [ "${openai_api}" == true ]; then
    flags+=(-H "Content-Type: application/json")
    chat_path='/api/chat/completions'
    filter='.choices[].delta.content // empty'
  else
    chat_path='/api/chat'
    filter='.message.content // empty'
  fi
  local response=$(curl "${flags[@]}" "${OLLAMA_URL}${chat_path}" \
    -d "${JSON_PAYLOAD}" | stdbuf -o0 sed 's/^data: //' \
    | stdbuf -o0 jq -j "${filter}" 2>/dev/null \
    | tee ${RESPONSE_FIFO})
  wait
  # Newline for AI response.
  if [ "${rich_format_mode}" != true ]; then
    echo
  fi
  # One line reponses do not print out when formatted with Streamdown.
  if [[ "$rich_format_path" == *"streamdown"* && \
    "${rich_format_mode}" == true ]]; then
    local wc=$(echo "${response}" | wc -l)
    if [ ${wc} -eq 1 ]; then
      echo "${response}"
    fi
  fi
  remove_response_trap
  remove_response_fifo
  echo
  update_history "assistant" "${response}"
  last_cmd="${response}"
}

#===============================================================================

check_requirements
if [ "${insecure_mode}" == true ]; then
  CURL_FLAGS+=('-k')
else
  check_cert
fi
if [ "${openai_api}" == true ]; then
  CURL_FLAGS+=(-H "Authorization: Bearer ${key}")
fi
cmd=chat_loop
set_default_agent

# Check arguments
for i in "$@"; do
  case $i in
    -h|--help)
      cmd=print_help
      ;;
    -l|--list)
      cmd=print_models
      ;;
    --delete)
      delete_chat_file
      exit 0
      ;;
    --load)
      select_chat_file
      source ${selected_file}
      cmd=chat_loop
      ;;
    --restore)
      if [ ! -e "${DATA_DIR}/autosave.chat" ]; then
        print_error 'auto save does not exit'
        exit ${ERROR_NO_AUTOSAVE}
      fi
      source "${DATA_DIR}/autosave.chat"
      cmd=chat_loop
      ;;
    # Modes
    --bash)
      set_coding_model
      set_bash_agent
      cmd=chat_loop
      ;;
    --cli)
      set_coding_model
      set_cli_agent
      cmd=chat_loop
      cli_mode=true
      rich_format_mode=false
      ;;
    --code-review)
      set_coding_model
      set_code_review_agent
      code_review_start=true
      cmd=chat_loop
      ;;
    --git)
      set_coding_model
      set_git_agent
      cmd=chat_loop
      cli_mode=true
      rich_format_mode=false
      ;;
    -r|--reason)
      set_reasoning_model
      cmd=chat_loop
      ;;
    --regex)
      set_coding_model
      set_regex_agent
      cmd=chat_loop
      rich_format_mode=false
      ;;
    -ha|--home-assistant)
      set_coding_model
      set_home_assistant_agent
      cmd=chat_loop
      rich_format_mode=false
      ;;
    # Other
    -*|--*)
      echo "Unknown option ${i}"
      print_help
      exit ERROR_UNKNOWN_OPTION
      ;;
  esac
done

${cmd}

