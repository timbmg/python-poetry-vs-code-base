#!/bin/bash

# ----- Project Name
project_default="project"
read -p "Project Name [${project_default}]: " project_name
project_name=${project_name:-$project_default}
cp pyproject.toml pyproject.tmp
sed "/^\[tool.poetry\]$/,/^\[/ s/^name = \"python-poetry-vs-code-base\"/name = \"${project_name}\"/" pyproject.tmp > pyproject.toml
rm pyproject.tmp

mkdir -p $project_name
touch ${project_name}/__init__.py

# ----- Author
author_default=$(dscl . -read "/Users/$(who am i | awk '{print $1}')" RealName | sed -n 's/^ //g;2p')
read -p "Authors [\"${author_default}\"]: " author
author=${author:-$author_default}
cp pyproject.toml pyproject.tmp
sed "/^\[tool.poetry\]$/,/^\[/ s/^authors = \[\"\"\]/authors = \[\"${author}\"\]/" pyproject.tmp > pyproject.toml
rm pyproject.tmp

# ----- Python Version
while true; do
    py_version_default="3.8.2"
    read -p "Python version for this project [${py_version_default}]: " py_version
    py_version=${py_version:-$py_version_default}
    escape_dot="\."
    escaped_py_version="${py_version//./\.}"
    num_versions_found="$(pyenv install --list | grep -c $escaped_py_version)"
    if [[ $num_versions_found -eq 1 ]]; then
        echo "Using Python ${py_version}"
        pyenv install -s ${py_version}
        pyenv local ${py_version}
        cp pyproject.toml pyproject.tmp
        sed "/^\[tool.poetry.dependencies\]$/,/^\[/ s/^python = \"^3.7\"/python = \"^${py_version}\"/" pyproject.tmp > pyproject.toml
        rm pyproject.tmp
        break
    elif [[ $num_versions_found -ge 2 ]]; then
        echo "Python version ${py_version} is ambigious. Found: $(pyenv install --list | grep $escaped_py_version)"
    else
        echo "Python version ${py_version} not found in pyenv. Try again."
    fi
done

# ----- Dependency Installtion
poetry install
poetry update

# ----- Set Python Path in .vscode
venv=$(poetry env info | grep "Path:*" | sed "s/^Path:[ \t]*//")
escaped_venv=$(echo $venv | sed -e 's/[\/&]/\\&/g')
cp .vscode/settings.json .vscode/settings.json.tmp
sed "s/\"python.pythonPath\": \"python\"/\"python.pythonPath\": \"${escaped_venv}\"/" .vscode/settings.json.tmp > .vscode/settings.json
rm .vscode/settings.json.tmp

# ----- Clean Up
git rm --cached -r .vscode

read -p "Delete Setup Script? [Y/n]" -n 1 deletion_decision
deletion_decision=${deletion_decision:-y}
if [[ $deletion_decision = ^[Yy]$ ]]; then
    git rm --cached setup.sh
    rm setup.sh
fi
exit