import tkinter as tk
import base64
import json
import requests
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_v1_5 as Cipher_pkcs1_v1_5
from tkinter import messagebox

# URL to fetch the password from CDN Download Server
PASSWORD_URL = ""

# Function to fetch and extract the password from the JSON file
def fetch_password():
    try:
        # Disabling SSL certificate verification
        response = requests.get(PASSWORD_URL, verify=False)
        response.raise_for_status()  # Will raise an exception for HTTP errors (4xx/5xx)
        data = response.json()
        return data.get("password", "")  # Assuming the JSON has a field "password"
    except requests.RequestException as e:
        print(f"Error fetching password: {e}")
        return ""

# Function for RSA encryption
def rsa_encrypt(message):
    cipher = Cipher_pkcs1_v1_5.new(RSA.importKey(public_key))
    return base64.b64encode(cipher.encrypt(message.encode())).decode()

# Function for RSA decryption
def rsa_decrypt(text):
    cipher = Cipher_pkcs1_v1_5.new(RSA.importKey(private_key))
    try:
        return cipher.decrypt(base64.b64decode(text), 'ERROR').decode('utf-8')
    except:
        return "Error: Invalid keys or format!"

# Function to decode password
def decode_passwd(passwd):
    tmp_str = passwd.replace(" ", "").replace("\n", "")
    for _ in range(4):
        offset = tmp_str[-2]
        if not offset.isdigit():
            raise Exception("Error: Invalid keys or format!")
        offset = int(offset)
        tmp_str = tmp_str[:-2]
        tmp_str = tmp_str[-offset:] + tmp_str[:-offset]
    return tmp_str[::-1]

# Function to check password input
def check_password():
    entered_password = password_entry.get()
    correct_password = fetch_password()
    
    if entered_password == correct_password:
        password_frame.pack_forget()  # Hide the password entry frame
        open_decryption_tool()  # Show the decryption tool
    else:
        messagebox.showerror("Authentication Failed", "Incorrect password. Access Denied.")
        app.quit()

# Function to open the decryption tool after authentication
def open_decryption_tool():
    global txt_entry
    tk.Label(app, text="Enter Encrypted Text:").pack()
    txt_entry = tk.Entry(app, width=50)
    txt_entry.pack()
    txt_entry.bind("<KeyRelease>", on_text_change)

    global result_text
    result_text = tk.StringVar()
    tk.Label(app, text="Decrypted Text:").pack()
    tk.Entry(app, textvariable=result_text, width=50, state="readonly").pack()

    global copy_button
    copy_button = tk.Button(app, text="Copy to Clipboard", command=copy_to_clipboard, state="disabled")
    copy_button.pack()

# Global variable for timer_id
timer_id = None

# Function for 3-second auto decryption
def on_text_change(event):
    global timer_id
    if timer_id:
        app.after_cancel(timer_id)
    timer_id = app.after(1000, decrypt_text)  # 3-second delay

# Decrypt text when input is changed
def decrypt_text():
    txt = txt_entry.get().replace(" ", "").replace("\n", "")
    try:
        decrypted_txt = decode_passwd(rsa_decrypt(txt)).replace(" ", "").replace("\n", "")
        result_text.set(decrypted_txt)
        # Enable copy button if there is a valid result
        if decrypted_txt and not decrypted_txt.startswith("Error"):
            copy_button.config(state="normal")
        else:
            copy_button.config(state="disabled")
    except Exception:
        result_text.set("Error: Invalid keys or format!")
        copy_button.config(state="disabled")

# Function to copy result to clipboard
def copy_to_clipboard():
    app.clipboard_clear()
    app.clipboard_append(result_text.get())
    messagebox.showinfo("Copied", "Decrypted text copied to clipboard!")

# RSA keys (assuming you will place your real keys here)
private_key = ''

# Public keys (assuming you will place your real keys here)
public_key = ''

# Initialize GUI
app = tk.Tk()
app.title("EDR QR Decryption Tool")

# Center the window on the screen
window_width, window_height = 400, 300  # Define the dimensions of the window
screen_width = app.winfo_screenwidth()
screen_height = app.winfo_screenheight()

x_cordinate = int((screen_width/2) - (window_width/2))
y_cordinate = int((screen_height/2) - (window_height/2))

app.geometry(f"{window_width}x{window_height}+{x_cordinate}+{y_cordinate}")

# Password entry frame
password_frame = tk.Frame(app)
password_frame.pack()

tk.Label(password_frame, text="Enter Password to Access Tool:").pack()
password_entry = tk.Entry(password_frame, show="*")  # Password input
password_entry.pack()

tk.Button(password_frame, text="Submit", command=check_password).pack()

# Run the GUI
app.mainloop()