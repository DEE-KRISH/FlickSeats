from flask import Flask,render_template,request,session,redirect,url_for,flash,jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin,login_user,logout_user,login_manager,LoginManager,login_required,current_user
from werkzeug.security import generate_password_hash,check_password_hash
from sqlalchemy import text
import datetime

app=Flask(__name__)
app.secret_key='PES'
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://@localhost:3307/flickseats'
db = SQLAlchemy(app)
session = db.session


#this is for getting unique user access
login_manager=LoginManager(app)
login_manager.login_view='login'

@login_manager.user_loader
def load_user(Customers_id):
    return Customers.query.get(int(Customers_id))

class Movies(db.Model):
    MovieID = db.Column(db.Integer,primary_key=True)
    Title = db.Column(db.String(50),unique=True)
    Genre = db.Column(db.String(50))
    ReleaseDate=db.Column(db.String(1000))
    Director=db.Column(db.String(1000))
    Description=db.Column(db.String(1000))

class Theaters(db.Model):
    TheaterID = db.Column(db.Integer,primary_key=True)
    Name = db.Column(db.String(50),unique=True)
    Location=db.Column(db.String(1000))


class Screens(db.Model):
    TheaterID = db.Column(db.Integer,primary_key=True)
    ScreenNumber = db.Column(db.Integer,primary_key=True)
    SeatNumber = db.Column(db.Integer,primary_key=True)

class Customers(UserMixin,db.Model):
    id = db.Column(db.Integer,primary_key=True)
    FirstName = db.Column(db.String(50))
    LastName = db.Column(db.String(50))
    Email=db.Column(db.String(1000),unique=True)
    Phone=db.Column(db.String(1000))
    Password=db.Column(db.String(1000))
    Wallet=db.Column(db.Integer)

class Bookings(db.Model):
    Bid = db.Column(db.Integer,primary_key=True)
    Title = db.Column(db.String(50))
    Name = db.Column(db.String(50))
    ScreenNumber = db.Column(db.Integer)
    SeatNumber = db.Column(db.Integer)
    Date=db.Column(db.DateTime)
    Payment=db.Column(db.Integer)
    CustomerID = db.Column(db.Integer)
    @staticmethod
    def calculate_total_revenue(theater_name):
        # total_revenue = db.session.query(db.func.sum(Bookings.Payment)).filter_by(Name=theater_name).scalar()
        query = text("SELECT SUM(Payment) FROM bookings WHERE Name = :theater_name;")
        parameters = {"theater_name": theater_name}
        total_revenue = db.session.execute(query, parameters)
        return total_revenue.fetchone()[0]

@app.route('/')
def index():
    return render_template('movie_index.html')



@app.route('/movies')
def movies():
    query = text("SELECT * FROM movies")
    movies = db.session.execute(query)
    return render_template('movie_movies.html',movies=movies)

@app.route('/min_page')
def min_page():
    query = text("SELECT * FROM movies where rating=(SELECT min(rating) FROM movies);")
    movies = db.session.execute(query)
    return render_template('movie_movies.html',movies=movies)
    

@app.route('/max_page')
def max_page():
    query = text("SELECT * FROM movies where rating=(SELECT max(rating) FROM movies);")
    movies = db.session.execute(query)
    return render_template('movie_movies.html',movies=movies)

@app.route('/wallet', methods=['GET'])
@login_required
def show_wallet():
    customer_id = current_user.id
    result = db.session.execute(text("CALL CalculateWallet(:customer_id, @wallet_money)"), {'customer_id': customer_id})
    money = db.session.execute(text('SELECT @wallet_money')).fetchone()[0]
    result.close()
    return render_template('movie_wallet.html', wallet_money=money)

@app.route('/preferece')    
def preference():
    result =  db.session.execute(text("""
        SELECT
            m.Title AS MovieTitle,
            c.FirstName,
            c.LastName,
            c.Email
        FROM
            customers c
        JOIN
            movies m ON EXISTS (
                SELECT 1
                FROM bookings b
                WHERE b.CustomerID = c.id AND b.Title = m.Title
            )
    """))
    return render_template("movie_preference.html",result=result)


@app.route('/theaters')
def theaters():
    query = text("SELECT * FROM theaters")
    theaters = db.session.execute(query)
    theaters_with_revenue = []

    # Iterate over theaters and calculate total revenue for each
    for theater in theaters:
        theater_name = theater.Name
        total_revenue = Bookings.calculate_total_revenue(theater_name)
        theaters_with_revenue.append({'theater': theater, 'total_revenue': total_revenue})

    return render_template('movie_theaters.html', theaters_with_revenue=theaters_with_revenue)


@app.route('/bookings', methods=['POST', 'GET'])
@login_required 
def bookings():
    movies = db.session.execute(text("SELECT * FROM movies"))
    theaters = db.session.execute(text("SELECT * FROM theaters"))
    screens = db.session.execute(text("SELECT * FROM screens"))

    if request.method == 'POST':
        Title = request.form.get('movie')
        Name = request.form.get('theater')
        ScreenNumber = request.form.get('screen')
        SeatNumber = request.form.get('seat')


        existing_booking_query = text("SELECT * FROM bookings WHERE (Title = :Title AND Name = :Name AND ScreenNumber = :ScreenNumber AND SeatNumber = :SeatNumber)")
        # Bind the parameters
        parameters = {"Title": Title, "Name": Name, "ScreenNumber": ScreenNumber, "SeatNumber": SeatNumber}

        text(" SELECT CalculateTotalRevenue(Name = :Name);")
        # Execute the query
        result = db.session.execute(existing_booking_query, parameters)

        # Check if a booking already exists
        if result.rowcount > 0:
            flash("Booking already exists", 'warning')
            return render_template('movie_bookings.html', movies=movies, theaters=theaters, screens=screens)

        # Construct the INSERT INTO query with placeholders
        insert_query = text("INSERT INTO bookings (Title, Name,ScreenNumber, SeatNumber,Date,Payment,CustomerID) VALUES (:Title, :Name,:ScreenNumber, :SeatNumber,:Date,:Payment,:CustomerID)")
        print(type(ScreenNumber))
        if str(ScreenNumber)=='1':
            Payment=100
        elif str(ScreenNumber)=='2':
            Payment=200
        else:
            Payment=300
        # Bind the parameters
        insert_parameters = {"Title": Title, "Name": Name,"ScreenNumber": ScreenNumber, "SeatNumber": SeatNumber,"Date": datetime.datetime.now(),"Payment": Payment, "CustomerID":current_user.id}

        # Execute the query
        db.session.execute(insert_query, insert_parameters)
        db.session.commit()

        flash("Booking success", 'info')
        return render_template('movie_index.html')

    return render_template('movie_bookings.html', movies=movies, theaters=theaters, screens=screens)

@app.route('/history')
@login_required
def history():
    query = text("SELECT * FROM bookings WHERE (CustomerID=:CustomerID)")
    parameters={"CustomerID":current_user.id}
    history = db.session.execute(query,parameters)
    return render_template('movie_history.html',history=history)

@app.route('/edit/<string:Bid>',methods=['POST','GET'])
@login_required
def edit(Bid):
    books=Bookings.query.get(Bid)

    if request.method == "POST":
        Title=request.form.get('movie')
        Name=request.form.get('theater')
        ScreenNumber=request.form.get('screen')
        SeatNumber=request.form.get('seat')

        if books:
            books.Title = Title
            books.Name = Name
            books.ScreenNumber = ScreenNumber
            books.SeatNumber = SeatNumber
            db.session.commit()
        flash("Booking is Updates", "success")
        return redirect('/history')
    return render_template('movie_edit.html',books=books)

@app.route('/delete/<string:Bid>',methods=['POST','GET'])
@login_required
def delete(Bid):
    book = Bookings.query.filter_by(Bid=Bid).first()
    db.session.delete(book)
    db.session.commit()

    flash("Booking Deleted Successful", "danger")
    return redirect('/bookings')

@app.route('/signup',methods=['POST','GET'])
def signup():
    if request.method == "POST":
        FirstName=request.form.get('FirstName')#in the name field
        LastName=request.form.get('LastName')#in the name field
        Email=request.form.get('Email')
        Phone=request.form.get('Phone') 
        password=request.form.get('password')
        Wallet=request.form.get('Wallet')
        existing_customer=Customers.query.filter_by(Email=Email).first()
        if existing_customer:
            flash("email already exists",'warning')
            return render_template('movie_signup.html')
        enc_password=generate_password_hash(password)
        new_customer = Customers(FirstName=FirstName,LastName=LastName,Phone=Phone,Email=Email, Password=enc_password,Wallet=Wallet)
        db.session.add(new_customer)
        db.session.commit()
        flash("Signup Succes Please Login","success")
        return render_template('movie_login.html')
    return render_template('movie_signup.html')


@app.route('/login',methods=['POST','GET'])
def login():
    if request.method == "POST":
        Email=request.form.get('Email')
        Password=request.form.get('Password')
        #print(email,password)
        existing_customer=Customers.query.filter_by(Email=Email).first()
        if existing_customer and check_password_hash(existing_customer.Password,Password):
            login_user(existing_customer)
            flash('Log in success','primary')
            return redirect(url_for('index'))
        else:
            flash('Invalid credentials','danger')
            return render_template('movie_login.html') 
    return render_template('movie_login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    flash("Logout successs",'success')
    return redirect(url_for('login'))

@app.route('/search',methods=['POST','GET'])
@login_required
def search():
    if request.method=="POST":
        query=request.form.get('search')
        # dept=Doctors.query.filter_by(dept=query).first()
        name=Movies.query.filter_by(Title=query).first()
        if name:

            flash("Movie is available","info")
        else:

            flash("Movie is Not Available","danger")
    return render_template('movie_index.html')


if __name__ == '__main__':
    app.run(debug=True)