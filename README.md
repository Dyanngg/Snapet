# Snapet

An iOS application aimed to provide a number-entering free, self adaptive, streamlined and smart expense tracking experience. Ideally, after a short period of usage (around a week or so for users who maintain consistent expense habits), once users upload new entries, Snapet should be intelligent enough to recognize expenses that has occurred before, auto-categorize these expenses and put them into place. 
<br />

## Installation

Simply download the zip file of the repository or clone the repository to your Github desktop application. 
In precaution of dependency errors, cd to the path of the downloaded project and do
```
pod install
```
Open the **Snapet.xcworkspace** file, select iPhone 7 Plus as default simulator, build and run.
<br />

## Features and Usage

<p align="center">
<img width="311" alt="screen shot 2017-05-02 at 8 56 06 pm" src="https://cloud.githubusercontent.com/assets/11527024/25645193/d50440cc-2f79-11e7-8c38-9cdbaaf1ff4f.png"> <img width="309" alt="screen shot 2017-05-02 at 8 56 19 pm" src="https://cloud.githubusercontent.com/assets/11527024/25645237/18e08eae-2f7a-11e7-8dec-97950de8e665.png">
</p>

  To add an new expense, use the camera button to take a snapshot, or upload single / batch photos from library using the upload button, or press the manual button on the top to manually add an entry.

<p align="center">
<img width="310" alt="screen shot 2017-05-02 at 9 04 02 pm" src="https://cloud.githubusercontent.com/assets/11527024/25645324/064183b0-2f7b-11e7-88d5-3e71da06a968.png">  <img width="307" alt="screen shot 2017-05-02 at 9 04 18 pm" src="https://cloud.githubusercontent.com/assets/11527024/25645333/10b3afe4-2f7b-11e7-9d50-e54efd92a1f1.png">
</p>

  After uploading, tap on any field to edit the information as needed, and zoom in on the uploaded image by force touching the confirmation image on the bottom.

<p align="center">
<img width="310" alt="screen shot 2017-05-02 at 9 08 22 pm" src="https://cloud.githubusercontent.com/assets/11527024/25645395/a761507c-2f7b-11e7-83e1-e663380d8f71.png"> <img width="311" alt="screen shot 2017-05-02 at 9 09 14 pm" src="https://cloud.githubusercontent.com/assets/11527024/25645399/b19a730c-2f7b-11e7-993b-96aa09e2d651.png">
</p>

  In the history page, search any expenses at a certain price range using the "<", "=" and ">" buttons under the search bar. Press one of the last two buttons and type in "date" or "category", to sort the expenses chronologically or alphabetically, descending / ascending.
  <br />
  
  
## Authors

* **Yang Ding** - *Dyanngg* - JSON interpretation algorithm, UI building
* **Duan Li** - *dxl360* - Core data implementation, testing


## Acknowledgments

APIs used: <br />
* [Charts](https://github.com/danielgindi/Charts)
* [KCFloatingActionButton](https://github.com/kciter/Floaty)
* [DKImagePickerController](https://github.com/zhangao0086/DKImagePickerController)
* [SWRevealViewController](https://github.com/John-Lluch/SWRevealViewController)


## License

[IMPORTANT] For those who wish to test out project for personal usage (to upload more than 5 images), please replace the Google API Key at the top of MainPageController and DetailViewController to your own. This will prevent the requests to Google Vision sent by our application to overflood.
