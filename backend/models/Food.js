import mongoose from "mongoose";

const foodSchema = new mongoose.Schema(
    {
        foodName: {
            type: String,
            required: true
        },

        quantity: {
            type: String,
            required: true
        },

        description: {
            type: String
        },

        preparedTime: {
            type: String
        },

        expiryTime: {
            type: String
        },

        location: {
            type: {
                type: String,
                enum: ["Point"],
                default: "Point"
            },

            coordinates: {
                type: [Number],
                required: true
            }
        },

        images: [
            {
                type: String
            }
        ],

        donorId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        status: {
            type: String,
            enum: ["available", "reserved", "picked"],
            default: "available"
        }

    },
    { timestamps: true }
);

foodSchema.index({ location: "2dsphere" });

const Food = mongoose.model("Food", foodSchema);

export default Food;