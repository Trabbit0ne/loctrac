from setuptools import setup, find_packages

setup(
    name="loctrac",
    version="0.1.0",
    author="PENTAGONE-GROUP",
    author_email="info@pentagone-group.com",
    description="IP Location Tracking Software",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/PENTAGONE-GROUP/loctrac",
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
    install_requires=[
        "folium",
        "geocoder",
        "requests",
    ],
    include_package_data=True,
    package_data={
        # If any package contains *.txt or *.rst files, include them:
        "": ["*.txt", "*.rst", "*.md"],
    },
)
