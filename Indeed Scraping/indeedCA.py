import numpy
import pandas as pd

from selenium import webdriver

# Starting/Stopping Driver: can specify ports or location but not remote access
from selenium.webdriver.chrome.service import Service as ChromeService

# Manages Binaries needed for WebDriver without installing anything directly
from webdriver_manager.chrome import ChromeDriverManager

# Allows searchs similar to beautiful soup: find_all
from selenium.webdriver.common.by import By

# Try to establish wait times for the page to load
from selenium.webdriver.support.ui import WebDriverWait

from selenium.webdriver.chrome.options import Options

# Call Sleep Function to log time of operations
import time

# Random integer for more realistic timing for clicks, buttons and searches during scraping
from random import randint

import selenium

from selenium.common.exceptions import NoSuchElementException

import csv
import re
from selenium.webdriver.support import expected_conditions as EC


# Allows you to cusotmize: ingonito mode, maximize window size, headless browser, disable certain features, etc
option = Options()
option.add_argument("--incognito")

paginaton_url = 'https://ca.indeed.com/jobs?q={}&l=Toronto%2C+ON&radius=50&start={}'

start = time.time()

jobs_=['Data+Analyst','Business+Analyst','Project+Coordinator']
# jobs_=['Business+Analyst']
location ='Toronto,ON'

for job_ in jobs_:

    driver = webdriver.Chrome(options=option)

    driver.get(paginaton_url.format(job_,0))

    time.sleep(5)

    p = driver.find_element(By.CLASS_NAME,'jobsearch-JobCountAndSortPane-jobCount').text
    
    # Max number of pages for this search! There is a caveat described soon
    max_iter_pgs=int(p.split('+')[0])//15 

    # Defining the table headers
    job_lst_header=['Job Title','Job URL','Job ID','Company Name','Job Location','Work Mode','Job Post Date']
    job_details_list_header=['Job ID','Job Type','Job Description','Salary','Benefits']
            
    for i in range(0,max_iter_pgs):

        job_lst=[]
        job_details_list = []
        
        driver.get(paginaton_url.format(job_,i*10))
        
        time.sleep(randint(2, 4))

        try:
            popup_button = driver.find_element(By.CLASS_NAME, "css-yi9ndv")
            popup_button.click()
    
        except NoSuchElementException:
            # Handle the case when the popup button is not found
            pass

        try:
            ok_button = WebDriverWait(driver, 5).until(
                EC.visibility_of_element_located((By.XPATH, "//button[@class='gnav-CookiePrivacyNoticeButton' and text()='OK']"))
            )
            ok_button.click()

        except:
            pass

        job_page = driver.find_element(By.ID,"mosaic-jobResults")
        jobs = job_page.find_elements(By.CLASS_NAME,"job_seen_beacon") # return a list
        for jj in jobs:

            job_title = jj.find_element(By.CLASS_NAME,"jobTitle")
            job_location_workmode_text = jj.find_element(By.CLASS_NAME, "css-1p0sjhy").text
            location_workmode_match = re.match(r"(Hybrid remote|Remote)?\s*in\s*(.*?)$", job_location_workmode_text)       #split work mode and job location text

            if location_workmode_match:
                job_location = location_workmode_match.group(2)
                work_mode = location_workmode_match.group(1) if location_workmode_match.group(1) else None
            else:
                job_location = job_location_workmode_text.strip()
                work_mode = None
            
            # Find the outer span element using XPath
            outer_span = driver.find_element(By.CLASS_NAME,"css-qvloho")

            # Get the text from the outer span element
            outer_text = outer_span.text

            # Find the inner span element using XPath within the outer span
            inner_span = outer_span.find_element(By.CLASS_NAME,"css-10pe3me")

            # Get the text from the inner span element
            inner_text = inner_span.text

            # Remove the inner text from the outer text
            job_post_date = outer_text.replace(inner_text, '').replace('ago','').strip()

            job_lst.append([
                job_title.text,                                                         # job title
                job_title.find_element(By.CSS_SELECTOR,"a").get_attribute("href"),      # job link
                job_title.find_element(By.CSS_SELECTOR,"a").get_attribute("id"),        # job ID      
                jj.find_element(By.CLASS_NAME,"css-63koeb").text,                       # company name
                job_location,                                                           # job location
                work_mode,                                                              # work mode
                job_post_date                                                           # job post date
                ])
        
                    
            # Click the job element to get the description
            job_title.click()
            
            # Help to load page so we can find and extract data
            time.sleep(randint(3, 5))

            #get job description text
            try:
                job_description = driver.find_element(By.ID, "jobDescriptionText").text

            except:
                job_description = None
        
            #get job type text
            try:
                job_type_element = driver.find_element(By.ID, "salaryInfoAndJobType")
                job_type_text = job_type_element.find_element(By.CLASS_NAME, "css-k5flys").text if job_type_element else None
                # Exclude the first three characters from job_type_text
                job_type = job_type_text.replace("-", "").strip() if job_type_text else None
            
            except:
                job_type = None

            #get job benefit text
            try:
                job_benefit = driver.find_element(By.CLASS_NAME, "css-8tnble").text

            except:
                job_benefit = None

            #get salary text
            try:
                job_salary = job_type_element.find_element(By.CLASS_NAME, "css-19j1a75").text if job_type_element else None

            except:
                job_salary = None

            # Append the job details to the job_details_list
            job_details_list.append([job_title.find_element(By.CSS_SELECTOR, "a").get_attribute("id"), job_type, job_description, job_salary, job_benefit])
            
        driver.quit()
        end = time.time()

        print(end - start,'seconds to complete Query!')
        print(max_iter_pgs,'pages of jobs!')

        encoding = 'utf-8'

        with open('job_lst.csv','a', newline='', encoding=encoding) as f1:  # Change 'w' to 'a' for append mode
            write = csv.writer(f1)
            # Only write the header if the file is empty
            if f1.tell() == 0:  # Check if the file is empty
                write.writerow(job_lst_header)
            write.writerows(job_lst)  # Append job_lst data

        with open('job_details_list.csv','a', newline='', encoding=encoding) as f2:  # Change 'w' to 'a' for append mode
            write = csv.writer(f2)
            # Only write the header if the file is empty
            if f2.tell() == 0:  # Check if the file is empty
                write.writerow(job_details_list_header)
            for row in job_details_list:
                if any(cell is not None and cell != "" for cell in row):
                    cleaned_row = [re.sub(r'(\$.*?)(\$)', r'\1-\2', re.sub(r'[^\x00-\x7F]', '', cell)) if cell is not None else None for cell in row]
                    write.writerow(cleaned_row)
            


    # with open('job_lst.csv','w', newline='', encoding=encoding) as f1:
    #     write = csv.writer(f1)
    #     write.writerow(job_lst_header)
    #     write.writerows(job_lst)

    # with open('job_details_list.csv','w', newline='', encoding=encoding) as f2:
    #     write = csv.writer(f2)
    #     write.writerow(job_details_list_header)
    #     for row in job_details_list:
    #         if any(cell is not None and cell != "" for cell in row):  # Check if any element in the row is not None or an empty string
    #             cleaned_row = [re.sub(r'(\$.*?)(\$)', r'\1-\2', re.sub(r'[^\x00-\x7F]', '', cell)) if cell is not None else None for cell in row]      #removed "??" and add "-"
    #             write.writerow(cleaned_row)
