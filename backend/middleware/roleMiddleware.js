export const donorOnly = (req, res, next) => {

    if (req.user.role !== "donor") {
        return res.status(403).json({
            error: "Access denied. Donors only."
        });
    }

    next();
};


export const ngoOnly = (req, res, next) => {

    if (req.user.role !== "ngo") {
        return res.status(403).json({
            error: "Access denied. NGOs only."
        });
    }

    next();
};