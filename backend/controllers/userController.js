import User from "../models/User.js";

/*
REGISTER USER
POST /api/users/register
*/

export const registerUser = async (req, res) => {
    try {

        const { name, email, role, lat, lng } = req.body;

        const existingUser = await User.findOne({ email });

        if (existingUser) {
            return res.status(400).json({
                error: "User already exists"
            });
        }

        const user = new User({
            name,
            email,
            role,

            location: {
                type: "Point",
                coordinates: [lng, lat]
            }
        });

        await user.save();

        res.status(201).json({
            message: "User registered successfully",
            user
        });

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }
};


/*
GET ALL USERS
GET /api/users
*/

export const getAllUsers = async (req, res) => {
    try {

        const users = await User.find();

        res.status(200).json(users);

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }
};