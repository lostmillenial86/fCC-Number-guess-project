#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo -e "\n~~~ Number Guess Game ~~\n"

# Prompt user for their username
echo "Enter your username:"
read USERNAME

# Validate username length
if [[ ${#USERNAME} -gt 22 ]]; then
  echo "Username too long! Please use up to 22 characters."
  exit 1
fi

# Check if user exists in the database
USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_DATA ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user into the database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
else
  # Parse user data
  GAMES_PLAYED=$(echo $USER_DATA | cut -d'|' -f1)
  BEST_GAME=$(echo $USER_DATA | cut -d'|' -f2)

  if [[ -z $BEST_GAME ]]; then
    BEST_GAME="N/A"
  fi

  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate a random secret number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
GUESS_COUNT=1

echo "Guess the secret number between 1 and 1000:"

while true; do
  read GUESS

  # Validate input
  if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  

  if [[ $GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
    ((GUESS_COUNT++))
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
    ((GUESS_COUNT++))
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
    
    # Update user stats
    UPDATE_USER_STATS_RESULT=$($PSQL "UPDATE users SET games_played = (games_played + 1) WHERE username='$USERNAME'")
    
    # Update best game if it's the best score or first recorded game
    CURRENT_BEST=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME'")
    if [[ -z "$CURRENT_BEST" || "$GUESS_COUNT" -lt "$CURRENT_BEST" ]]; then
      UPDATE_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game = $GUESS_COUNT WHERE username='$USERNAME'")
    fi

    break
  fi
done