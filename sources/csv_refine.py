#!/usr/bin/python3

import argparse
import pandas as pd

'''
This function converts simple datetime into Unix timestamp
'''
def convertDatetimeToTimestamp(datetime):
  dates = pd.to_datetime([datetime])
  retval = (dates - pd.Timestamp("1970-01-01")) // pd.Timedelta('1ms')
  return retval[0]

'''
This function takes an IP as a string input, converts it into HEX first 
(as it would look like in a packet), then convert that HEX into INT!
'''
def convertIP(ip):
  retval = ""
  #split IP address into 4 8-bit values
  ip_segments=ip.split(".")
  #convert it to HEX
  for i in ip_segments:
    retval+=str("%0.2X" % int(i))
  
  if len(retval) != 8: #check length of IP
    print("ERROR during parsing IP address - not long enough!: {}".format(ip))
    exit(-1)

  return int(retval, 16)


'''
This function does the actual conversion
'''
def convertData(input,output):
  df = pd.read_csv(input)
  columns = ["sa" , "da", "sp", "dp", "pr", "ts", "td", "ipkt", "ibyt"]
  df = pd.DataFrame(df, columns=columns)
  #convert raw data columns into the one NetShare wants
  df['ts'] = df['ts'].apply(convertDatetimeToTimestamp)
  df['sa'] = df['sa'].apply(convertIP)
  df['da'] = df['da'].apply(convertIP)

  column_match_netshare={
    'sa' : 'srcip',
    'da' : 'dstip',
    'sp' : 'srcport',
    'dp' : 'dstport',
    'pr' : 'proto',
    'ts' : 'ts',
    'td' : 'td',
    'ipkt' : 'pkt',
    'ibyt' : 'byt'
  }
  df = df.rename(columns=column_match_netshare)
  # print(df)
  df.to_csv(output, index=False, sep=',', encoding='utf-8')

'''
Main thread
'''
if __name__ == "__main__":
  # Parsing input args
  parser = argparse.ArgumentParser(description="csv_refine.py script")
  parser.add_argument('-i', 
                      '--input', 
                      dest="input",
                      help="Specify the input csv file",
                      required=True)

  parser.add_argument('-o', 
                      '--output', 
                      dest="output",
                      help="Specify the output csv file",
                      required=True)
  args = parser.parse_args()
  input=args.input
  output=args.output

  #call the main function that does the thing
  convertData(input, output)
