from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium import webdriver
import argparse

chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")

driver = webdriver.Chrome(options=chrome_options)

#driver.get("https://bgp.he.net/AS15169#_prefixes")

driver.get("https://hackertarget.com/as-ip-lookup/")

search = driver.find_element(By.NAME, "theinput")
search.send_keys("mercadona")
search.submit()

try:
    element = WebDriverWait(driver, 20).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, "#myTable_wrapper"))
    )
    print(element.text)
finally:
    driver.quit()