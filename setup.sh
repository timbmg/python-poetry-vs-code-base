#!/bin/bash

# ----- Project Name
read -p "Project Name [project]: " project_name
project_name=${project_name:-project}
sed "/^\[tool.poetry\]$/,/^\[/ s/^name = \"python-poetry-vs-code-base\"/name = \"${project_name}\"/" pyproject.toml > pyproject.toml

mkdir -p $project_name
touch ${project_name}/__init__.py

# ----- Author
author=$(dscl . -read "/Users/$(who am i | awk '{print $1}')" RealName | sed -n 's/^ //g;2p')
read -p "Authors [\"${author}\"]: " author
authors=${author:-$(author)}
sed "/^\[tool.poetry\]$/,/^\[/ s/^authors = \[\"\"\]/authors = \[\"${author}\"\]/" pyproject.toml > pyproject.toml

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
        sed "/^\[tool.poetry.dependencies\]$/,/^\[/ s/^python = \"^3.8.0\"/python = \"^${py_version}\"/" pyproject.toml > pyproject.toml
        break
    elif [[ $num_versions_found -ge 2 ]]; then
        echo "Python version ${py_version} is ambigious. Found: $(pyenv install --list | grep $escaped_py_version)"
    else
        echo "Python version ${py_version} not found in pyenv. Try again."
    fi
done

# ----- Dependency Installtion
poetry update
poetry install

# ----- Clean Up
read -p "Delete Setup Script? [Y/n]" -n 1 deletion_decision
deletion_decision=${deletion_decision:-y}
if [[ $deletion_decision = ^[Yy]$ ]]
    then
        # rm setup.sh
        echo "rm"
fi
exit