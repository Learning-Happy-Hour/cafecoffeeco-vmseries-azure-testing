#! /bin/bash
sudo apt-get update
sudo sleep 10s
sudo apt-get install -y apache2
sudo sleep 10s
echo '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cafe Coffee Co</title>
    <style>
        /* Add your CSS styling here */
        body {
            font-family: Arial, sans-serif;
            background-color: #ffeecc;
            text-align: center;
        }

        header {
            background-color: #3b1c32;
            color: #ffeecc;
            padding: 20px;
        }

        h1 {
            font-size: 2.5em;
        }

        nav {
            background-color: #381e32;
            padding: 10px;
        }

        nav a {
            text-decoration: none;
            color: #ffeecc;
            margin: 10px;
        }

        .container {
            max-width: 960px;
            margin: 0 auto;
            padding: 20px;
        }

        .coffee-image {
            width: 100%;
            max-width: 600px;
        }

        footer {
            background-color: #3b1c32;
            color: #ffeecc;
            padding: 10px;
        }
    </style>
</head>
<body>
    <header>
        <h1>Welcome to Cafe Coffee Co</h1>
    </header>
    <nav>
        <a href="#about">About Us</a>
        <a href="#menu">Menu</a>
        <a href="#contact">Contact</a>
    </nav>
    <div class="container">
        <section id="about">
            <h2>About Us</h2>
            <p>Cafe Coffee Co is a family-owned coffee shop founded by Ronen and Hadi. We are passionate about serving the finest coffee and creating a cozy atmosphere for our customers.</p>
            <img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAAAAAAAD/4QCMRXhpZgAATU0AKgAAAAgAA1EQAAEAAAABAQAA/EA4QAAAARgAAAAA/9sAQwADAgIDAgIDAwIDAwMDAwMCAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCAS1A3UDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnGywnJfEA8QHwRAeT4eHhEYAxKPFjY2PTgiJyebEzJDRj5OjshgBkPTVN6enF2dJzVWFj5DLuXl5KT2alY+gd6UjnF/gwraTl5uJ4gHhdWQ9JwQHkOYvFps+Jny3pQHih7Gw69T1H/2Q=="
                alt="Coffee Shop" class="coffee-image">
        </section>
        <section id="menu">
            <h2>Our Menu</h2>
            <p>Explore our wide range of coffee and delicious pastries.</p>
            <!-- Add your menu items here -->
        </section>
        <section id="contact">
            <h2>Contact Us</h2>
            <p>If you have any questions or inquiries, please feel free to contact us.</p>
            <p>Email: info@cafecoffeeco.com</p>
            <p>Phone: +1 (123) 456-7890</p>
        </section>
    </div>
    <footer>
        &copy; 2023 Cafe Coffee Co
    </footer>
</body>
</html>' | sudo tee /var/www/html/index.html
