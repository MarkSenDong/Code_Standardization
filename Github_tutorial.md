# Getting started with GitHub

## 1. The 10 minutes quick start guide (The absolute essentials to get started)
Reference: https://guides.github.com/activities/hello-world/<br>
You’ll learn how to:<br>
- Create and use a repository
- Start and manage a new branch
- Make changes to a file and push them to GitHub as commits
- Open and merge a pull request
<br>

## 2. Video Tutorial series from Github official channel on Youtube
Reference: https://www.youtube.com/playlist?list=PLg7s6cbtAD15G8lNyoaYDuKZSKyJrgwB-<br>
**Recommended to watch in order to get a comprehensive understanding of the concept of Git as well as most of the main functions!!!**<br>
<br>

## 3. Additional tips
**1). New Repository**<br>
Please find the botton to create new repository at the top left corner of your main dashboard once logged in.<br>
<img src="images/2.new_repo.png" width="600">
<br>
 
**2). Private Repository**<br>
If you do not want to allow the public to have access to your reppository, please remember to select **private repository** upon creation.<br>
If you want to change your repo privacy setting after the creation, you can find it in 'Settings' at the top right corner of the repo's main page, scroll to the bottom where it says 'Danger Zone' and modify privacy setting there.<br>
**To change your repo's privacy settings later on, simply follow the short tutorial here:<br>
https://help.github.com/en/articles/setting-repository-visibility**<br>
<br>

**3). .gitignore**<br>
If you want to upload local files to github, but you would like to ignore some specific file types from uploading, you can select the file type to be ignored here.<br>
Ignored files are usually build artifacts and machine generated files that can be derived from your repository source or should otherwise not be committed. Some common examples are:<br>

* dependency caches, such as the contents of /node_modules or /packages
* compiled code, such as .o, .pyc, and .class files
* build output directories, such as /bin, /out, or /target
* files generated at runtime, such as .log, .lock, or .tmp
* hidden system files, such as .DS_Store or Thumbs.db
* personal IDE config files, such as .idea/workspace.xml

Ignored files are tracked in a special file named .gitignore that is checked in at the root of your repository. There is no explicit git ignore command: instead the .gitignore file must be edited and committed by hand when you have new files that you wish to ignore. .gitignore files contain patterns that are matched against file names in your repository to determine whether or not they should be ignored.

**Check the following page for the list of gitignore commands:**<br>
https://www.atlassian.com/git/tutorials/saving-changes/gitignore
<br>

**4). Choosing an appropriate open source license**<br>
If you would like to publish your code one day to the public, in order to avoid copyright infringement or other issues, you can select a default open source lisnece to go with your repo.<br>
**You can find a guide on how to choose open source license here:<br>
https://choosealicense.com/**<br>
<br>
<img src="images/3.create_new_repo.png">
<br>

**5). README.md**<br>
Reference: https://guides.github.com/features/wikis/<br>
It is mandatory to include a README.md file in your repo, just like in this repo.<br>
READMEs generally follow one format in order to immediately orient developers to the most important aspects of your project.<br>
<br>
* **Project name:** Your project’s name is the first thing people will see upon scrolling down to your README, and is included upon creation of your README file.

* **Description:** A description of your project follows. A good description is clear, short, and to the point. Describe the importance of your project, and what it does.

* **Table of Contents:** (Optional) Include a table of contents in order to allow other people to quickly navigate especially long or detailed READMEs.

* **Installation:** Installation is the next section in an effective README. Tell other users how to install your project locally. Optionally, include a gif to make the process even more clear for other people.

* **Usage:** The next section is usage, in which you instruct other people on how to use your project after they’ve installed it. This would also be a good place to include screenshots of your project in action.

* **Contributing:** Larger projects often have sections on contributing to their project, in which contribution instructions are outlined. Sometimes, this is a separate file. If you have specific contribution preferences, explain them so that other developers know how to best contribute to your work. To learn more about how to help others contribute, check out the guide for setting guidelines for repository contributors.

* **Credits:** Include a section for credits in order to highlight and link to the authors of your project.

* **License:** Finally, include a section for the license of your project. For more information on choosing a license, check out GitHub’s licensing guide!

Your README should contain only the necessary information for developers to get started using and contributing to your project. Longer documentation is best suited for wikis, outlined below.<br>
<br>
It has different syntax than normal text editing or word.<br>
**If you need help on how to stylise your README.md file, click the link here:<br>
https://help.github.com/en/articles/basic-writing-and-formatting-syntax**<br>
<br>

**6). Wiki**<br>
Reference: https://guides.github.com/features/wikis/<br>
Every repository on GitHub comes with a wiki. After you’ve created a repository, you can set up the included wiki through the sidebar navigation. Starting your wiki is simply a matter of clicking the wiki button and creating your first page.<br>
<img src="images/wiki-blank-slate.png" width="600"><br>

* **Adding content:** Wiki content is designed to be easily editable. You can add or change content on any wiki page by clicking the Edit button located in the upper right corner of each page. This opens up the wiki editor. Wiki pages can be written in any format supported by GitHub Markup. Using the drop-down menu in the editor, you can select the format of your wiki, and then use wiki toolbar to create and include content on a page. Wikis also give you the option of including a custom footer where you can list things like contact details or license information for your project.

GitHub keeps track of changes made to each page in your wiki. Below a page title, you can see who made the most recent edits, in addition to the number of commits made to the page. Clicking on this information will take you to the full page history where you can compare revisions or see a detailed list of edits over time.

* **Adding pages:** You can add additional pages to your wiki by selecting New Page in the upper right corner. By default, each page you create is included automatically in your wiki’s sidebar and listed in alphabetical order. ou can also add a custom sidebar to your wiki by clicking the Add custom sidebar link. Custom sidebar content can include text, images, and links. Note: The page called “Home” functions as the entrance page to your wiki. If it is missing, an automatically generated table of contents will be shown instead.

* **Syntax highlighting:** Wiki pages support automatic syntax highlighting of code for a wide range of languages by using the following syntax. The block must start with three backticks, optionally followed by the the name of the language that is contained by the block. See Pygments for the list of languages that can be syntax highlighted.The block contents should be indented at the same level as the opening backticks. The block must end with three backticks indented at the same level as the opening backticks.

**7). Github GUI**<br>
Git by default is a commandline tool.<br>
As a website, Github gives you the option to use an online GUI for managing your repo.<br>
But if you want to take a step further and use Github as a desktop software with GUI, there are 2 options.<br> 
<br>
&nbsp;&nbsp;&nbsp;&nbsp;**Github Desktop**(*Windows, MacOS, not available for Linux*):<br>
&nbsp;&nbsp;&nbsp;&nbsp;Download link: https://desktop.github.com/<br>
&nbsp;&nbsp;&nbsp;&nbsp;**Short Getting Started Video (9 mins): https://www.youtube.com/watch?v=ci3W1T88mzw**<br>
&nbsp;&nbsp;&nbsp;&nbsp;Tutorials: https://help.github.com/en/desktop/getting-started-with-github-desktop<br>
&nbsp;&nbsp;&nbsp;&nbsp;One of the most convenient way of using github, and most of the time I use it to manage and work with github.<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;**Gitkraken**(*Linux, MacOS, Windows*):<br>
&nbsp;&nbsp;&nbsp;&nbsp;Download link: https://www.gitkraken.com/download<br>
&nbsp;&nbsp;&nbsp;&nbsp;How to install: https://support.gitkraken.com/how-to-install/<br>
&nbsp;&nbsp;&nbsp;&nbsp;Link Gitkraken to your Github account: https://support.gitkraken.com/integrations/github/<br>
&nbsp;&nbsp;&nbsp;&nbsp;**Short Getting Started Video (6 mins): https://www.youtube.com/watch?v=ub9GfRziCtU**<br>
&nbsp;&nbsp;&nbsp;&nbsp;Basic Tutorials: https://support.gitkraken.com/start-here/guide/<br>
&nbsp;&nbsp;&nbsp;&nbsp;I have not used it since I work mainly on Windows PC. But for Linux users, Github Desktop is not yet available.<br>
&nbsp;&nbsp;&nbsp;&nbsp;In this case, Gitkraken is one of the best Github GUI out there, and it is free for personal use.<br>
<br>
