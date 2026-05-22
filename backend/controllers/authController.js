import { OAuth2Client } from "google-auth-library";
import User from "../models/User.js";
import generateToken from "../utils/generateToken.js";

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

export const googleAuth = async (req, res) => {
    try {

        const { token, role, lat, lng } = req.body;

        const ticket = await client.verifyIdToken({
            idToken: token,
            audience: process.env.GOOGLE_CLIENT_ID
        });

        const payload = ticket.getPayload();

        const { email, name } = payload;

        let user = await User.findOne({ email });

        if (!user) {

            user = new User({
                name,
                email,
                role,
                location: {
                    type: "Point",
                    coordinates: [lng, lat]
                }
            });

            await user.save();
        }

        const jwtToken = generateToken(user._id);

        res.json({
            token: jwtToken,
            user
        });

    } catch (error) {

        res.status(500).json({
            error: error.message
        });

    }
};