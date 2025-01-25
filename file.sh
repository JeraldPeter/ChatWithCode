#!/bin/bash

# Check if required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <branch1> <branch2> <repo_list_file> <email_address>"
    exit 1
fi

# Arguments
BRANCH1=$1
BRANCH2=$2
REPO_LIST_FILE=$3
EMAIL_ADDRESS=$4

# Validate the repo list file
if [ ! -f "$REPO_LIST_FILE" ]; then
    echo "Error: File $REPO_LIST_FILE does not exist."
    exit 1
fi

# Directory to store cloned repositories
WORK_DIR="cloned_repos"

# File to store HTML email content
HTML_FILE="git_log_results.html"

# Clean up existing working directory and HTML file
if [ -d "$WORK_DIR" ]; then
    echo "Cleaning up existing directory: $WORK_DIR"
    rm -rf "$WORK_DIR"
fi
if [ -f "$HTML_FILE" ]; then
    echo "Cleaning up existing HTML file: $HTML_FILE"
    rm -f "$HTML_FILE"
fi

# Create a fresh working directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Start the HTML email content
cat <<EOF > "../$HTML_FILE"
<!DOCTYPE html>
<html>
<head>
    <title>Git Log Comparison Results</title>
    <style>
        body { font-family: Arial, sans-serif; }
        h1 { color: #333; }
        h2 { color: #555; }
        pre { background-color: #f4f4f4; padding: 10px; border: 1px solid #ddd; }
    </style>
</head>
<body>
<h1>Git Log Comparison Results</h1>
<p>Branches compared: <strong>$BRANCH1</strong> vs <strong>$BRANCH2</strong></p>
<hr>
EOF

# Loop through repositories from the file
while read -r REPO; do
    # Skip empty lines or comments
    if [[ -z "$REPO" || "$REPO" =~ ^# ]]; then
        continue
    fi

    REPO_NAME=$(basename -s .git "$REPO")
    echo "Processing repository: $REPO_NAME"
    
    # Add repository details to the HTML file
    echo "<h2>Repository: $REPO_NAME</h2>" >> "../$HTML_FILE"

    # Clone the repository
    git clone "$REPO" "$REPO_NAME"

    # Enter the repository directory
    cd "$REPO_NAME"

    # Fetch all branches
    git fetch origin

    # Check out the first branch
    git checkout $BRANCH1
    git pull origin $BRANCH1

    # Check out the second branch
    git checkout $BRANCH2
    git pull origin $BRANCH2

    # Compare the branches and append to the HTML file
    echo "<h3>Commits in <code>$BRANCH2</code> not in <code>$BRANCH1</code>:</h3>" >> "../../$HTML_FILE"
    echo "<pre>" >> "../../$HTML_FILE"
    git log "$BRANCH1..$BRANCH2" --oneline >> "../../$HTML_FILE"
    echo "</pre>" >> "../../$HTML_FILE"

    # Return to the working directory
    cd ..
    echo "--------------------------------------------"
done < "../$REPO_LIST_FILE"

# Close the HTML file
echo "</body></html>" >> "../$HTML_FILE"

# Send the email with HTML content
echo "Sending email to $EMAIL_ADDRESS..."
mail -a "Content-Type: text/html" -s "Git Log Comparison Results" "$EMAIL_ADDRESS" < "../$HTML_FILE"

echo "HTML email sent successfully to $EMAIL_ADDRESS."
