import unicode
import re
import pandas as pd

def remove_accents(text):
  """
  Returns the author name string with no special characters
  """
    if pd.isna(text):
        return text
    return ''.join(
        c for c in unicodedata.normalize('NFKD', text)
        if not unicodedata.combining(c)
    )

def normalize_author(name):
  """
  Normalizes the names, making them upper case
  """
    if pd.isna(name):
        return name

    name = remove_accents(name)
    name = name.upper()
    name = re.sub(r'\.', '', name)
    name = re.sub(r'\s+', ' ', name).strip()
    return name

# Load the data from the CSV file
df = pd.read_csv('nyt_bestsellers_full.csv')

# Apply the `normalize_author` function
df['author_clean'] = df['author'].apply(normalize_author)
df['author'] = df['author_clean']
df = df.drop(columns=['author_clean'])

# Replace `AND`, `&`, `WITH` from the author column with `|` for easier splitting later
df['author'] = (
    df['author']
    .str.replace(r'\s+(AND|&|WITH)\s+', '|', regex=True)
)

# Replace `,` from the author column with `|` for easier splitting later
df['author'] = (
    df['author']
    .str.replace(r'\,', '|',regex=True)
)

# Remove unwanted substrings from the author name
texts_to_remove = [
    'INTRODUCTION BY',
    'WITH WORDS BY',
    'EDITED BY',
    'ILLUSTRATED BY',
    'ILLLUSTRATED BY',
    'WITH A FOREWORD BY',
    'PHOTOGRAPHED BY',
    'BIOGRAPHICAL TEXT BY',
    'ADAPTED BY',
    'INTRODUCED BY',
    'NOVELIZATION BY',
    'LYRICS BY',
    'SELECTED BY',
    'COMPILED BY',
    'PHOTOS BY',
    'CREATED BY',
    'WITH AN INTRODUCTION BY',
    'WITH RELATED MATERIALS BY',
    'FROM TEXTS BY',
    'PHOTOGRAPHY BY',
    'WRITTEN BY',
    'RECIPES BY',
    'SUPPORTING MATERIALS BY',
    'DRAWINGS BY',
    'PHOTOGRAPHS BY',
    'CONTRIBUTIONS BY'
]
for text in texts_to_remove:
  df['author'] = (
      df['author']
      .str.replace(text,'')
      .str.strip()
  )

# Special string cases:
## Remove `BY` in `BY JOHN GROGAN`
df['author'] = (
    df['author']
    .str.replace('BY JOHN GROGAN','JOHN GROGAN')
    .str.strip()
)

# Change `TRANSLATED BY` into `|` to split later
df['author'] = (
    df['author']
    .str.replace('TRANSLATED BY','|')
    .str.strip()
)

# Split co-authored books separated with `|`
df['author'] = df['author'].str.split('|')
df = df.explode('author')
df['author'] = df['author'].str.strip()

# Save the dataset with clean `author` column
df.to_csv('new_csv.csv')
