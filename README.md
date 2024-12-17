# CSV File Manager

This project is designed to manage and interpret CSV files containing student data for various exams. A CSV file stores data in a table-like structure with rows and columns separated by commas. Each CSV file in this project contains data in the format:
`<Roll_Number,Name,Marks>`. This script provides various commands to manipulate and analyze these files effectively.

---

## **Commands**

### **combine**

Creates `main.csv` by combining data from all available CSV files in the directory. Each exam contributes a column in `main.csv`, with rows representing students. Students absent in any exam will have an "a" in place of their marks. Rows are case-insensitive and represent the union of all students across exams.

### **upload**

Uploads a new CSV file to the directory, ensuring it is included in future `combine` operations.

### **total**

Adds a "total" column to `main.csv`, summing the marks of each student across all exams. Absent marks are treated as 0. Running `combine` will update the totals accordingly.

### **update**

Allows updating marks for specific students. Input includes the roll number, student name, and marks for different exams. This updates only the individual CSV files, combine/total needs to be called to update `main.csv`.

---

### **Version Control Commands**

#### **git\_init**

Initializes a remote repository to store versions of the current directory. If the specified directory does not exist, it is created.
Example:

```bash
bash submission.sh git_init ~/Desktop/repo
```

#### **git\_commit**

Commits the current version of the directory to the remote repository, generating a unique 16-digit hash ID and storing the commit message in `.git_log`. Modified files since the last commit are displayed.
Example:

```bash
bash submission.sh git_commit "Initial commit"
```

#### **git\_checkout**

Reverts the current directory to a specified commit. You can use a full or partial hash ID. If multiple commits have the same prefix of hash, all the possible hash IDs are displayed.
Example:

```bash
bash submission.sh git_checkout 8193
```

#### **git\_add**

Adds files to the tracking list to ensure they are included in commits.

```bash
bash submission.sh git_add file1.csv
```

#### **git\_rm**

Removes files from the tracking list to exclude them from future commits.

```bash
bash submission.sh git_rm file1.csv
```

#### **git\_status**

Displays the current status of tracked and untracked files since the last commit.

```bash
bash submission.sh git_status
```

#### **git\_log**

Displays a list of all commits with their hash IDs and commit messages.

```bash
bash submission.sh git_log
```

---

