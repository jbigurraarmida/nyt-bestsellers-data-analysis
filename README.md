# New York Times Bestseller list analysis

## Project Overview
 
This project explores historical trends in New York Times bestsellers list between 2010 and 2025, using data collected from the NYT API and additional metadata sources.

This project focuses on:
- Author and publisher dominance
- Ranking and longevity in the list
- Genre trends
- Title word patterns
- Ranking trajectories over time

## Research Questions

- Which authors dominated the #1 spot?
- Which publishers had the most successful titles?
- How did TV adaptations affect book rankings?
- Which words become more common in bestseller titles over time?
- Which genres showed the strongest long-term presence?

## Dataset
The data was collected from:
- New York Times Books API

The data set includes:
- Weekly bestseller rankings
- Titles
- Authors
- Publishers
- ISBNs
- Ranking history (rank last week)
- Dates

The dataset covers the period from 2010 to 2025.

## Technologies used
- Python
  - Pandas
  - SQLite3
  - Matplotlib
- Google Colab
- Tableau

## Environment variables
Create a `.env` file and add your NYT API key:
```env
NYT_API_KEY=your_api_key_here
```

## Getting the data
To obtain the book data, we used the New York Times API, and the `requests` library.

```Python
while date <= end:
	params = {
		"published_date": date.strftime("%Y-%m-%d"),
		"api-key": api_key
	}
	r = requests.get(url, params=params)
```

The API responses were parsed and transformed into structured rows, and saved into a csv file for further analysis.

## Data Cleaning & Processing
First, we transformed both author and publisher names into upper case letters.

### Cleaning author names
Having the authors names into upper case, we normalized the authors names, so that there were no special characters and duplicates because of it, such as:

| author         | book |
|----------------|------|
| ROBERTO BOLAÑO | 2666 |
| ROBERTO BOLANO | 2666 |

Obtaining, in this example:

| author         | book |
|----------------|------|
| ROBERTO BOLANO | 2666 |

Other problem the data had was co-authored books, especially if we wanted to know how many times an author appeared on the list, no matter if their books were written alone or with other authors.

To do so, first, we replaced all instances where the authors name had `AND`, `&`, `WITH`, `,`, or `;` with `|` so later we could split both authors, so instead of having:

| author                            | book              |
|-----------------------------------|-------------------|
| ROBERT JORDAN & BRANDON SANDERSON | A MEMORY OF LIGHT |

We obtain after splitting them:

| author            | book              |
|-------------------|-------------------|
| ROBERT JORDAN     | A MEMORY OF LIGHT |
| BRANDON SANDERSON | A MEMORY OF LIGHT |

But after doing so, there was yet another problem: there were books with text such as `INTRODUCTION BY`, `WITH WORDS BY`, `ILLUSTRATED BY`, `NOVELIZATION BY`, `WRITTEN BY`, etc. So, gathering in a list all such texts producing noise in the author column, we removed them.

## Interactive Dashboard
(Coming soon)

## Future Improvements
- Expand genre classification
- Add sentiment analysis
- Develop predictive ranking models

## Repository Structure

/scripts
    Data collection and preprocessing scripts

/notebooks
    Exploratory data analysis and visualizations

/sql
    SQL queries used for analysis

/images
    Visualizations and dashboard screenshots

/tableau
    Tableau dashboard files
